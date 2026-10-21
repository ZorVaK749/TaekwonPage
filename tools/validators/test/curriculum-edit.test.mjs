import assert from 'node:assert/strict';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { createCurriculumEditSql } from '../../seeders/export-curriculum-edit-sql.mjs';
import { createImportFixture } from '../fixtures/import-dataset.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';

function fixture() {
  return { id: 'gup_10', expected_revision: 0, requirements: createImportFixture().dataset.curricula[0].requirements,
    reason: "Synthetic ' reason $$", operator_reference: 'Unverified test operator' };
}

test('curriculum edit exports one guarded transaction and sorts IDs without mutating input', async () => {
  const edit = fixture();
  edit.requirements.position_ids = ['fixture_z', 'fixture_a'];
  const before = structuredClone(edit);
  const sql = await createCurriculumEditSql(edit);
  assert.match(sql, /BEGIN;\nSELECT revise_curriculum_draft\(/);
  assert.match(sql, /COMMIT;\n$/);
  assert.ok(sql.includes('["fixture_a","fixture_z"]'));
  assert.ok(sql.includes("E'Synthetic '' reason $$'"));
  assert.deepEqual(edit, before);
});

test('curriculum edit rejects malformed IDs, unsafe revisions and implicit actors/reasons', async () => {
  for (const change of [{ id: 'gup_0' }, { id: 'gup_10\n' }, { id: 'fixture_position' },
    { expected_revision: -1 }, { expected_revision: '0' }, { expected_revision: 0.5 },
    { expected_revision: Number.MAX_SAFE_INTEGER + 1 }, { reason: ' ' }, { operator_reference: null }]) {
    await assert.rejects(createCurriculumEditSql({ ...fixture(), ...change }));
  }
});

test('all seven typed ID arrays are required, unique, canonical and not embedded definitions', async () => {
  for (const change of [
    (r) => { delete r.position_ids; },
    (r) => { r.position_ids = null; },
    (r) => { r.position_ids = ['fixture_position', 'fixture_position']; },
    (r) => { r.position_ids = [{ id: 'fixture_position' }]; },
    (r) => { r.position_ids = ['Bad ID']; },
    (r) => { r.unexpected_ids = []; },
    (r) => { for (const key of Object.keys(r)) r[key] = []; },
  ]) {
    const edit = fixture();
    change(edit.requirements);
    await assert.rejects(createCurriculumEditSql(edit));
  }
});

test('curriculum editor cannot include publication, citation changes or new grade numbers', async () => {
  for (const extra of [{ review_status: 'approved' }, { citation_ids: [] }, { gup: 9 }, { name: 'Changed' }]) {
    await assert.rejects(createCurriculumEditSql({ ...fixture(), ...extra }));
  }
});

test('curriculum edit CLI requires explicit consent and a readable local payload', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-curriculum-edit-sql.mjs');
  for (const args of [[], ['--local-curriculum-edit', 'missing-synthetic-curriculum-edit.json']]) {
    const result = spawnSync(process.execPath, [script, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
  }
});
