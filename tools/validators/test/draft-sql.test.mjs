import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import path from 'node:path';
import test from 'node:test';
import { createDraftSql, exportDraftSql, sqlValue } from '../../seeders/export-draft-sql.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';
import { createImportFixture } from '../fixtures/import-dataset.mjs';

test('SQL values escape quotes and backslashes; unsupported values fail closed', () => {
  assert.equal(sqlValue("a'b\\c"), "E'a''b\\\\c'");
  assert.equal(sqlValue(null), 'NULL');
  assert.equal(sqlValue(false), 'FALSE');
  for (const value of ['a\0b', {}, [], Infinity, NaN]) assert.throws(() => sqlValue(value));
});

test('actual drafts export atomically with typed rows and unknown counts preserved', async () => {
  const sql = await exportDraftSql();
  const count = (table) => sql.split(`INSERT INTO ${table} (`).length - 1;
  assert.equal(count('source_document'), 4);
  assert.equal(count('content_entry'), 78);
  assert.equal(count('content_source'), 140);
  assert.equal(count('tul_step'), 15);
  assert.equal(count('tul_step_source'), 15);
  assert.equal(count('gup'), 0);
  assert.match(sql, /BEGIN;\n/);
  assert.match(sql, /COMMIT;\n$/);
  assert.ok(sql.includes('ON CONFLICT (id) DO NOTHING'));
  assert.ok(sql.includes('assert_draft_import'));
  assert.ok(!sql.includes('UPDATE vocabulary'));
  assert.match(sql, /E'saju_jirugi', NULL, E'narani_junbi_sogi', FALSE/);
});

test('synthetic curriculum maps all seven typed requirement groups with its own citation', async () => {
  const { dataset, inventory } = createImportFixture();
  const before = structuredClone(dataset);
  const sql = await createDraftSql(dataset, inventory);
  assert.ok(sql.includes("INSERT INTO gup (id, gup) VALUES (E'gup_10', 10)"));
  for (const table of ['gup_position', 'gup_theory', 'gup_vocabulary', 'gup_tool', 'gup_kick', 'gup_tul', 'gup_combat']) {
    assert.ok(sql.includes(`INSERT INTO ${table} (`));
    assert.ok(sql.includes(`FROM ${table} WHERE gup_id = E'gup_10') = 1`));
  }
  assert.ok(sql.includes("E'citation_import_curriculum', E'gup_10'"));
  assert.deepEqual(dataset, before);
});

test('invalid, uncited and wrong-type curriculum requirements fail before generating SQL', async () => {
  for (const change of [
    (dataset) => { dataset.curricula[0].requirements.position_ids = ['missing_position']; },
    (dataset) => { dataset.curricula[0].requirements.position_ids = ['fixture_theory']; },
    (dataset) => { dataset.curricula[0].citation_ids = []; },
    (dataset) => { dataset.curricula[0].review_status = 'approved'; },
  ]) {
    const { dataset, inventory } = createImportFixture();
    change(dataset);
    await assert.rejects(createDraftSql(dataset, inventory));
  }
});

test('reload guards compare exact rows and child membership without destructive SQL', async () => {
  const { dataset, inventory } = createImportFixture();
  dataset.curricula[0].requirements.position_ids = [];
  const sql = await createDraftSql(dataset, inventory);
  assert.match(sql, /LOCK TABLE .* IN SHARE ROW EXCLUSIVE MODE/);
  assert.ok(sql.includes("FROM gup_position WHERE gup_id = E'gup_10') = 0"));
  assert.ok(sql.includes("FROM tul_step WHERE tul_id = E'fixture_tul') = 1"));
  assert.ok(sql.includes('aliases IS NOT DISTINCT FROM ARRAY['));
  assert.ok(!/\b(DELETE FROM|TRUNCATE|DO UPDATE)\b/.test(sql));
});

test('CLI requires explicit local-drafts consent and has no SQL on refusal', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-draft-sql.mjs');
  const result = spawnSync(process.execPath, [script], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  const sql = execFileSync(process.execPath, [script, '--local-drafts'], { encoding: 'utf8' });
  assert.match(sql, /LOCAL DRAFTS ONLY/);
});
