import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import path from 'node:path';
import test from 'node:test';
import { exportDraftSql, sqlValue } from '../../seeders/export-draft-sql.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';

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
  assert.equal(count('content_entry'), 31);
  assert.equal(count('content_source'), 51);
  assert.equal(count('tul_step'), 15);
  assert.equal(count('tul_step_source'), 15);
  assert.equal(count('gup'), 0);
  assert.match(sql, /BEGIN;\n/);
  assert.match(sql, /COMMIT;\n$/);
  assert.ok(!sql.includes('ON CONFLICT'));
  assert.match(sql, /E'saju_jirugi', NULL, E'narani_junbi_sogi', FALSE/);
});

test('CLI requires explicit local-drafts consent and has no SQL on refusal', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-draft-sql.mjs');
  const result = spawnSync(process.execPath, [script], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  const sql = execFileSync(process.execPath, [script, '--local-drafts'], { encoding: 'utf8' });
  assert.match(sql, /LOCAL DRAFTS ONLY/);
});
