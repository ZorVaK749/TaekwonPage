import assert from 'node:assert/strict';
import test from 'node:test';
import { createDetailEditSql } from '../../seeders/export-detail-edit-sql.mjs';

const fixture = () => ({ id: 'fixture_tul', expected_revision: 0, content_type: 'tul', reason: 'Synthetic test.',
  operator_reference: 'Unverified test operator', details: {
    movement_count: null, initial_position_id: null, sequence_complete: false, sequence_scope: 'Synthetic partial list.',
    steps: [{ step_number: 1, position_id: 'fixture_position', description: 'Synthetic only.', citation_ids: ['citation_fixture'] }],
  } });

test('exercise editor preserves unknown totals/preparation and does not derive a full sequence', async () => {
  const edit = fixture();
  const before = structuredClone(edit);
  const sql = await createDetailEditSql(edit);
  assert.match(sql, /SELECT revise_tul_draft\(/);
  assert.ok(sql.includes('"movement_count":null'));
  assert.ok(sql.includes('"initial_position_id":null'));
  assert.ok(sql.includes('"sequence_complete":false'));
  assert.deepEqual(edit, before);
});

test('synthetic complete sequences require count, preparation and all contiguous steps', async () => {
  const edit = fixture();
  Object.assign(edit.details, { movement_count: 1, initial_position_id: 'fixture_position', sequence_complete: true, sequence_scope: null });
  await createDetailEditSql(edit);
  for (const change of [{ movement_count: null }, { movement_count: 2 }, { initial_position_id: null }, { steps: [] }]) {
    await assert.rejects(createDetailEditSql({ ...edit, details: { ...edit.details, ...change } }));
  }
});

test('partial exercise steps require scope, valid numbering and explicit own citation IDs', async () => {
  for (const mutate of [
    (d) => { d.sequence_scope = null; }, (d) => { d.sequence_scope = ' '; },
    (d) => { d.steps.push(structuredClone(d.steps[0])); },
    (d) => { d.steps[0].step_number = 0; }, (d) => { d.steps[0].step_number = 2147483648; },
    (d) => { d.movement_count = 2147483648; }, (d) => { d.steps[0].citation_ids = []; },
    (d) => { d.steps[0].citation_ids = ['citation_fixture', 'citation_fixture']; },
    (d) => { d.steps[0].position_id = 'Bad ID'; }, (d) => { d.steps[0].invented_angle = 90; },
  ]) {
    const edit = fixture();
    mutate(edit.details);
    await assert.rejects(createDetailEditSql(edit));
  }
});

test('empty partial exercises stay explicit and citation order normalization is non-mutating', async () => {
  const edit = fixture();
  edit.details.steps[0].citation_ids = ['citation_z', 'citation_a'];
  const sql = await createDetailEditSql(edit);
  assert.ok(sql.includes('["citation_a","citation_z"]'));
  assert.deepEqual(edit.details.steps[0].citation_ids, ['citation_z', 'citation_a']);
  edit.details.steps = [];
  edit.details.sequence_scope = null;
  await createDetailEditSql(edit);
});
