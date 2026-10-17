import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const positions = await load('catalogs/posiciones/posiciones_iniciales.json');
const positionCitations = await load('provenance/posiciones_iniciales.json');
const preparatory = await load('catalogs/posiciones/posicion_preparatoria_paralela.json');
const preparatoryCitations = await load('provenance/posicion_preparatoria_paralela.json');
const exercises = await load('catalogs/tuls/ejercicios_iniciales_parciales.json');
const exerciseCitations = await load('provenance/ejercicios_iniciales_parciales.json');
const dataset = {
  catalogs: [positions, preparatory, exercises], curricula: [],
  provenance: [positionCitations, preparatoryCitations, exerciseCitations],
};

test('specific preparatory variant validates without copying legacy geometry', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.equal(preparatory.items.length, 1);
  assert.equal(preparatory.items[0].id, 'narani_junbi_sogi');
  assert.equal(preparatory.items[0].biomechanics, null);
  assert.equal(preparatory.items[0].review_status, 'pending_human_review');
});

test('preparatory evidence records observed PDF page and printed folio separately', () => {
  const citation = preparatoryCitations.citations[0];
  assert.equal(citation.source_id, 'source_enciclopedia_taekwondo');
  assert.equal(citation.pdf_page, 81);
  assert.equal(citation.printed_page, '79');
  assert.equal(citation.content_id, 'narani_junbi_sogi');
  assert.equal(citation.review_status, 'pending_human_review');
});

test('exercise preparation points to the specific sourced variant, not generic Junbi', () => {
  for (const exercise of exercises.items) {
    assert.equal(exercise.initial_position_id, preparatory.items[0].id);
    assert.ok(exercise.citation_ids.includes(`citation_${exercise.id}_enciclopedia_p530`));
    assert.equal(exercise.movement_count, null);
    assert.equal(exercise.sequence_complete, false);
  }
  assert.ok(!dataset.catalogs.flatMap((catalog) => catalog.items).some((item) => item.id === 'junbi_sogi'));
});

test('removing the preparatory catalog cannot leave a silently valid initial reference', () => {
  const changed = structuredClone(dataset);
  changed.catalogs = changed.catalogs.filter((catalog) => catalog !== changed.catalogs[1]);
  changed.provenance = changed.provenance.filter((document) => document !== changed.provenance[1]);
  assert.match(validator.validateDataset(changed, inventory).join(), /missing or wrong-type position reference narani_junbi_sogi/);
});

test('resolved initial references do not hide unknown totals or partial sequences in report', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.counts.documented_steps, 15);
  for (const exercise of exercises.items) {
    assert.ok(!report.incomplete_observations.sequences_without_initial_position.includes(exercise.id));
    assert.ok(report.incomplete_observations.sequences_with_unknown_movement_count.includes(exercise.id));
    assert.ok(report.incomplete_observations.partial_sequences.includes(exercise.id));
  }
});

test('a sourced preparation still cannot imply curriculum completion or publication approval', () => {
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
  const changed = structuredClone(preparatory);
  changed.items[0].review_status = 'approved';
  assert.notEqual(validator.validateCatalog(changed).length, 0);
});
