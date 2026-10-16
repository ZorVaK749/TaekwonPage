import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const vocabulary = await load('catalogs/vocabulario/vocabulario_inicial.json');
const citations = await load('provenance/vocabulario_inicial.json');
const theory = await load('catalogs/teoria/teoria_inicial.json');
const theoryCitations = await load('provenance/teoria_inicial.json');
const dataset = { catalogs: [vocabulary], curricula: [], provenance: [citations] };

// Technical regression checks; no claim of human approval or martial correctness.
test('real vocabulary lot validates with its registered source references', () => {
  assert.equal(vocabulary.catalog_type, 'vocabulary');
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('four vocabulary IDs remain pending, each with two page-specific citations', () => {
  assert.deepEqual(vocabulary.items.map((item) => item.id), ['dobok', 'ti', 'dojang', 'boo_sabum_nim']);
  assert.equal(citations.citations.length, 8);
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  for (const item of vocabulary.items) {
    assert.equal(item.review_status, 'pending_human_review');
    const linked = item.citation_ids.map((id) => byId.get(id));
    assert.equal(linked.length, 2);
    const locations = linked.map((citation) => [citation.source_id, citation.pdf_page]);
    assert.deepEqual(locations, item.id === 'boo_sabum_nim' ? [
      ['source_teoria_completa_web', 6], ['source_teoria_ont', 7],
    ] : [
      ['source_teoria_completa_web', 11], ['source_teoria_ont', 13],
    ]);
    for (const citation of linked) {
      assert.equal(citation.content_id, item.id);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.printed_page, null);
    }
  }
});

test('observed spelling variants are preserved without importing unsupported legacy aliases', () => {
  const items = new Map(vocabulary.items.map((item) => [item.id, item]));
  assert.deepEqual(items.get('dojang').aliases, ['Do jang']);
  assert.deepEqual(items.get('boo_sabum_nim').aliases, ['Busabonim']);
  assert.ok(!items.has('charyot'));
  assert.ok(!items.has('kyong_ye'));
});

test('real theory and vocabulary compose without duplicate IDs or orphan citations', () => {
  const combined = {
    catalogs: [theory, vocabulary], curricula: [], provenance: [theoryCitations, citations],
  };
  assert.deepEqual(validator.validateDataset(combined, inventory), []);
});

test('martial vocabulary cannot carry application role fields', () => {
  const changed = structuredClone(vocabulary);
  changed.items.find((item) => item.id === 'boo_sabum_nim').roles = ['ROLE_ADMIN'];
  assert.match(validator.validateCatalog(changed).join(), /unevaluated|additional/);
});

test('vocabulary extraction does not imply a completed curriculum', () => {
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
});
