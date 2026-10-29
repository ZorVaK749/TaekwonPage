import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const exercises = await load('catalogs/tuls/ejercicios_iniciales_parciales.json');
const citations = await load('provenance/ejercicios_iniciales_parciales.json');
const positions = await load('catalogs/posiciones/posiciones_iniciales.json');
const positionCitations = await load('provenance/posiciones_iniciales.json');
const preparatory = await load('catalogs/posiciones/posicion_preparatoria_paralela.json');
const preparatoryCitations = await load('provenance/posicion_preparatoria_paralela.json');
const dataset = { catalogs: [exercises, positions, preparatory], curricula: [], provenance: [citations, positionCitations, preparatoryCitations] };

test('15 observed actions have ordered local numbering and step-specific source links', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.equal(exercises.items.reduce((sum, item) => sum + item.steps.length, 0), 15);
  for (const item of exercises.items) {
    assert.deepEqual(item.steps.map((step) => step.step_number), item.steps.map((_, index) => index + 1));
    for (const step of item.steps) {
      assert.equal(step.position_id, 'gunnun_sogi');
      assert.deepEqual(step.citation_ids, [`citation_${item.id}_enciclopedia_p530`]);
    }
    assert.equal(item.movement_count, null);
    assert.equal(item.initial_position_id, 'narani_junbi_sogi');
    assert.equal(item.sequence_complete, false);
  }
});

test('partial steps without a declared scope are rejected', () => {
  const changed = structuredClone(dataset);
  delete changed.catalogs[0].items[0].sequence_scope;
  assert.match(validator.validateDataset(changed, inventory).join(), /explicit sequence_scope/);
});

test('whitespace-only sequence scope is rejected by schema', () => {
  const changed = structuredClone(exercises);
  changed.items[0].sequence_scope = ' \n\t';
  assert.notEqual(validator.validateCatalog(changed).length, 0);
});

test('earlier empty partial draft shape remains supported without an invented scope', () => {
  const changed = structuredClone(dataset);
  for (const item of changed.catalogs[0].items) {
    item.steps = [];
    delete item.sequence_scope;
  }
  assert.deepEqual(validator.validateDataset(changed, inventory), []);
});

test('a missing book citation cannot be masked by retaining a terminology citation', () => {
  const changed = structuredClone(dataset);
  changed.provenance[0].citations = changed.provenance[0].citations
    .filter((citation) => citation.source_id !== 'source_enciclopedia_taekwondo');
  assert.match(validator.validateDataset(changed, inventory).join(), /unknown citation ID/);
});

test('the illegible action target stays explicit instead of being silently inferred', () => {
  const item = exercises.items.find((entry) => entry.id === 'saju_jirugi');
  assert.match(item.steps[2].description, /destino del golpe no es legible/);
  assert.match(item.sequence_scope, /punto 3 no es legible/);
  const bookCitation = citations.citations.find((citation) => citation.id === 'citation_saju_jirugi_enciclopedia_p530');
  assert.match(bookCitation.notes, /erosionada y no queda traza legible/);
  assert.match(bookCitation.notes, /no se completa por simetría/);
});

test('review report distinguishes documented actions, missing totals and partial sequences', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.counts.documented_steps, 15);
  for (const item of exercises.items) {
    assert.ok(report.incomplete_observations.partial_sequences.includes(item.id));
    assert.ok(report.incomplete_observations.sequences_with_unknown_movement_count.includes(item.id));
    assert.ok(!report.incomplete_observations.sequences_without_initial_position.includes(item.id));
  }
  assert.ok(report.validation.not_checked.includes('martial_accuracy'));
});

test('observed PDF page and printed folio remain independent verified locators', () => {
  const bookCitations = citations.citations.filter((citation) => citation.source_id === 'source_enciclopedia_taekwondo');
  assert.equal(bookCitations.length, 2);
  for (const citation of bookCitations) {
    assert.equal(citation.pdf_page, 530);
    assert.equal(citation.printed_page, '528');
    assert.equal(citation.review_status, 'pending_human_review');
  }
});
