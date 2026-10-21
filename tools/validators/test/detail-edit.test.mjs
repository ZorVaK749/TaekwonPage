import assert from 'node:assert/strict';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { createDetailEditSql } from '../../seeders/export-detail-edit-sql.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';

const fixture = () => ({ id: 'fixture_position', expected_revision: 0, content_type: 'position',
  details: { front_percent: null, rear_percent: null, front_rotation_deg: null, rear_rotation_deg: null },
  reason: 'Synthetic test only.', operator_reference: 'Unverified fixture operator' });

test('detail SQL preserves unknown numeric values instead of filling them with zeros', async () => {
  const edit = fixture();
  const before = structuredClone(edit);
  const sql = await createDetailEditSql(edit);
  assert.match(sql, /BEGIN;\nSELECT revise_catalog_details\(/);
  assert.ok(sql.includes('"front_percent":null'));
  assert.ok(sql.includes('"rear_rotation_deg":null'));
  assert.deepEqual(edit, before);
});

test('vocabulary details preserve explicit translation, alias order and escaped literals', async () => {
  const edit = { ...fixture(), content_type: 'vocabulary', id: 'fixture_vocabulary',
    details: { translation: "Synthetic ' translation", aliases: ['Z', 'A'] } };
  const sql = await createDetailEditSql(edit);
  assert.ok(sql.includes("Synthetic '' translation"));
  assert.ok(sql.includes('["Z","A"]'));
});

test('position details reject invalid totals, partial pairs, strings, rotations and invented geometry', async () => {
  for (const details of [
    { front_percent: 60, rear_percent: 50, front_rotation_deg: null, rear_rotation_deg: null },
    { front_percent: 50, rear_percent: null, front_rotation_deg: null, rear_rotation_deg: null },
    { ...fixture().details, front_rotation_deg: 360 }, { ...fixture().details, front_rotation_deg: -1 },
    { ...fixture().details, front_rotation_deg: NaN }, { ...fixture().details, front_rotation_deg: Infinity },
    { ...fixture().details, rear_rotation_deg: '25' }, { ...fixture().details, x: 1 }, {},
  ]) await assert.rejects(createDetailEditSql({ ...fixture(), details }));
});

test('vocabulary details reject blank, duplicate or non-string aliases', async () => {
  for (const details of [{ translation: ' ', aliases: [] }, { translation: 'Test', aliases: ['A', 'A'] },
    { translation: 'Test', aliases: [' '] }, { translation: 'Test', aliases: [1] }]) {
    await assert.rejects(createDetailEditSql({ ...fixture(), content_type: 'vocabulary', details }));
  }
});

test('detail edits require explicit scope/reason/operator and cannot smuggle approval', async () => {
  for (const change of [{ content_type: 'tul' }, { expected_revision: -1 }, { expected_revision: '0' },
    { id: 'id\n' }, { reason: ' ' }, { operator_reference: null }, { review_status: 'approved' }]) {
    await assert.rejects(createDetailEditSql({ ...fixture(), ...change }));
  }
});

test('detail editor CLI fails without consent or a readable payload and emits no SQL', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-detail-edit-sql.mjs');
  for (const args of [[], ['--local-detail-edit', 'missing-synthetic-detail-edit.json']]) {
    const result = spawnSync(process.execPath, [script, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
  }
});
