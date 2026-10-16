import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { discoverCatalogFiles, discoverJsonFiles } from '../lib/content-files.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const tools = await load('catalogs/herramientas/herramientas_iniciales.json');
const toolCitations = await load('provenance/herramientas_iniciales.json');
const exercises = await load('catalogs/tuls/ejercicios_iniciales_parciales.json');
const exerciseCitations = await load('provenance/ejercicios_iniciales_parciales.json');
const dataset = { catalogs: [tools, exercises], curricula: [], provenance: [toolCitations, exerciseCitations] };

// Technical traceability tests; they do not verify martial truth or approval.
test('real tools and exercise drafts validate as seven items with eleven citations', () => {
  assert.equal(tools.items.length, 5);
  assert.equal(exercises.items.length, 2);
  assert.equal(toolCitations.citations.length + exerciseCitations.citations.length, 11);
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('body-tool citations retain exact observed copies and PDF pages', () => {
  const expected = new Map([
    ['ap_joomuk', [['source_teoria_completa_web', 11], ['source_teoria_ont', 14]]],
    ['palmok', [['source_teoria_completa_web', 12], ['source_teoria_ont', 15]]],
    ['bakat_palmok', [['source_teoria_completa_web', 12], ['source_teoria_ont', 15]]],
    ['an_palmok', [['source_teoria_completa_web', 12], ['source_teoria_ont', 15]]],
    ['sonkal', [['source_teoria_ont', 14]]],
  ]);
  const byId = new Map(toolCitations.citations.map((citation) => [citation.id, citation]));
  for (const item of tools.items) {
    assert.equal(item.review_status, 'pending_human_review');
    assert.deepEqual(item.citation_ids.map((id) => {
      const citation = byId.get(id);
      assert.equal(citation.content_id, item.id);
      assert.equal(citation.printed_page, null);
      return [citation.source_id, citation.pdf_page];
    }), expected.get(item.id));
  }
});

test('terminology entries never become inferred exercise steps or legacy movement counts', () => {
  assert.deepEqual(exercises.items.map((item) => item.id), ['saju_jirugi', 'saju_makgi']);
  for (const item of exercises.items) {
    assert.equal(item.movement_count, null);
    assert.equal(item.initial_position_id, null);
    assert.equal(item.sequence_complete, false);
    assert.deepEqual(item.steps, []);
    assert.equal(item.review_status, 'pending_human_review');
  }
  for (const citation of exerciseCitations.citations) {
    assert.equal(citation.source_id, 'source_terminologia_formas');
    assert.equal(citation.pdf_page, 1);
    assert.equal(citation.printed_page, null);
  }
});

test('claiming these partial exercises are complete is rejected', () => {
  const changed = structuredClone(dataset);
  changed.catalogs[1].items[0].sequence_complete = true;
  assert.match(validator.validateDataset(changed, inventory).join(), /complete sequence/);
});

test('new extraction still cannot satisfy presence gate without a curriculum', () => {
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
});

test('new actual source evidence cannot be relabeled with a different PDF hash', () => {
  const changed = structuredClone(dataset);
  changed.provenance[1].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
});

test('all real drafts compose and report the two exercise sequences as partial', async () => {
  const catalogFiles = await discoverCatalogFiles(path.join(repositoryRoot, 'knowledge/catalogs'));
  const provenanceFiles = await discoverJsonFiles(path.join(repositoryRoot, 'knowledge/provenance'));
  const full = {
    catalogs: await Promise.all(catalogFiles.map(({ file }) => readJson(file))), curricula: [],
    provenance: await Promise.all(provenanceFiles.map((file) => readJson(file))),
  };
  assert.deepEqual(validator.validateDataset(full, inventory), []);
  const report = createReviewReport({ inventory, ...full }, { contentReferencesChecked: true });
  for (const id of ['saju_jirugi', 'saju_makgi']) {
    assert.ok(report.incomplete_observations.partial_sequences.includes(id));
    assert.ok(report.pending_human_review.content_ids.includes(id));
  }
  assert.ok(report.source_usage.find((source) => source.source_id === 'source_terminologia_formas').citation_count >= 2);
});
