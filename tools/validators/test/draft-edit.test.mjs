import assert from 'node:assert/strict';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { createDraftEditSql } from '../../seeders/export-draft-edit-sql.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';

const fixture = () => ({ id: 'fixture_position', expected_revision: 0, name: "Synthetic ' name",
  description: 'Synthetic \\ description $$', reason: 'Test only.', operator_reference: 'Unverified test operator.' });

test('draft text edit exports one guarded transaction without direct updates', () => {
  const edit = fixture();
  const before = structuredClone(edit);
  const sql = createDraftEditSql(edit);
  assert.match(sql, /BEGIN;\nSELECT revise_content_draft\(/);
  assert.match(sql, /COMMIT;\n$/);
  assert.ok(sql.includes("E'Synthetic '' name'"));
  assert.ok(!sql.includes('UPDATE content_entry'));
  assert.deepEqual(edit, before);
});

test('unverified local operator and reason must both be explicit', () => {
  for (const field of ['operator_reference', 'reason', 'name', 'description']) {
    const edit = fixture();
    edit[field] = '   ';
    assert.throws(() => createDraftEditSql(edit));
  }
});

test('draft text edits cannot smuggle publication, IDs or subtype changes', () => {
  for (const field of ['review_status', 'content_type', 'new_id', 'biomechanics', 'requirements']) {
    assert.throws(() => createDraftEditSql({ ...fixture(), [field]: 'unwanted' }));
  }
  for (const value of [null, [], {}, { ...fixture(), id: 'invalid\n' }]) assert.throws(() => createDraftEditSql(value));
});

test('expected revision is a nonnegative safe integer, not a coercible string', () => {
  for (const expected_revision of [-1, 0.5, '0', null, Number.MAX_SAFE_INTEGER + 1]) {
    assert.throws(() => createDraftEditSql({ ...fixture(), expected_revision }));
  }
});

test('CLI refuses edits without explicit consent or readable payload without producing SQL', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-draft-edit-sql.mjs');
  for (const args of [[], ['--local-draft-edit', 'nonexistent-edit-fixture.json']]) {
    const result = spawnSync(process.execPath, [script, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
  }
});
