import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/teoria/teoria_temario_inicial.json');
const citations = await load('provenance/teoria_temario_inicial.json');
const initial = await load('catalogs/teoria/teoria_inicial.json');
const symbolism = await load('catalogs/teoria/teoria_simbolismo_inicial.json');
const dataset = { catalogs: [initial, symbolism, added], curricula: [], provenance: [
  await load('provenance/teoria_inicial.json'), await load('provenance/teoria_simbolismo_inicial.json'), citations,
] };

test('two documentary theory additions compose with previous drafts and four copy-specific citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['etimologia_taekwondo', 'clasificacion_instructores']);
  assert.equal(citations.citations.length, 4);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 7);
});

test('new theory evidence preserves observed PDF locations and unverified printed folios', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  for (const item of added.items) {
    assert.equal(item.review_status, 'pending_human_review');
    const locations = item.citation_ids.map((id) => {
      const citation = byId.get(id);
      assert.equal(citation.content_id, item.id);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.printed_page, null);
      return [citation.source_id, citation.pdf_page];
    });
    assert.deepEqual(locations, item.id === 'etimologia_taekwondo'
      ? [['source_teoria_completa_web', 2], ['source_teoria_ont', 2]]
      : [['source_teoria_completa_web', 6], ['source_teoria_ont', 7]]);
  }
});

test('instructor classification cannot acquire application roles through a theory draft', () => {
  const changed = structuredClone(added);
  changed.items[1].roles = ['ROLE_ADMIN'];
  assert.match(validator.validateCatalog(changed).join(), /additional|unevaluated/);
});

test('new evidence cannot silently change source identity or imply human approval', () => {
  const changed = structuredClone(dataset);
  changed.provenance[2].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
  const approved = structuredClone(added);
  approved.items[0].review_status = 'approved';
  assert.notEqual(validator.validateCatalog(approved).length, 0);
});

test('review matrix maps to actual theory IDs but cannot substitute a real curriculum', async () => {
  const matrix = await readFile(path.join(repositoryRoot, 'knowledge/provenance/temario_teorico_10gup-review.md'), 'utf8');
  for (const item of dataset.catalogs.flatMap((catalog) => catalog.items)) assert.ok(matrix.includes(`\`${item.id}\``));
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
});

test('theory coverage report still exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.theory, 7);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 7);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
