import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { discoverCatalogFiles, discoverJsonFiles } from '../lib/content-files.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const positions = await load('catalogs/posiciones/posiciones_iniciales.json');
const positionCitations = await load('provenance/posiciones_iniciales.json');
const symbolism = await load('catalogs/teoria/teoria_simbolismo_inicial.json');
const symbolismCitations = await load('provenance/teoria_simbolismo_inicial.json');
const dataset = {
  catalogs: [positions, symbolism], curricula: [], provenance: [positionCitations, symbolismCitations],
};

test('real position and symbolism lots validate with ten linked citations', () => {
  assert.equal(positions.items.length, 3);
  assert.equal(symbolism.items.length, 2);
  assert.equal(positionCitations.citations.length + symbolismCitations.citations.length, 10);
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('position weights are scoped observations; no foot rotations are inferred', () => {
  const byId = new Map(positions.items.map((item) => [item.id, item]));
  assert.equal(byId.get('charyot_sogi').biomechanics, null);
  assert.deepEqual(byId.get('gunnun_sogi').biomechanics.weight, { front_percent: 50, rear_percent: 50 });
  assert.deepEqual(byId.get('niunja_sogi').biomechanics.weight, { front_percent: 30, rear_percent: 70 });
  for (const id of ['gunnun_sogi', 'niunja_sogi']) {
    assert.equal(byId.get(id).biomechanics.front_foot, null);
    assert.equal(byId.get(id).biomechanics.rear_foot, null);
  }
  assert.ok(!byId.has('junbi_sogi'), 'Do not infer an initial stance variant from the legacy draft.');
});

test('actual stance citations use PDF pages, not guessed printed folios', () => {
  const expected = new Map([
    ['charyot_sogi', [24, 31]], ['gunnun_sogi', [24, 32]], ['niunja_sogi', [24, 32]],
  ]);
  const byId = new Map(positionCitations.citations.map((citation) => [citation.id, citation]));
  for (const item of positions.items) {
    assert.deepEqual(item.citation_ids.map((id) => byId.get(id).pdf_page), expected.get(item.id));
    assert.equal(item.review_status, 'pending_human_review');
  }
  for (const citation of positionCitations.citations) {
    assert.equal(citation.printed_page, null);
    assert.equal(citation.review_status, 'pending_human_review');
  }
});

test('symbolism keeps independent IDs rather than overriding vocabulary concepts', () => {
  assert.deepEqual(symbolism.items.map((item) => item.id), ['significado_dobok_blanco', 'significado_cinturon_blanco']);
  for (const item of symbolism.items) assert.equal(item.review_status, 'pending_human_review');
  const byId = new Map(symbolismCitations.citations.map((citation) => [citation.id, citation]));
  assert.deepEqual(symbolism.items[0].citation_ids.map((id) => byId.get(id).pdf_page), [6, 7]);
  assert.deepEqual(symbolism.items[1].citation_ids.map((id) => byId.get(id).pdf_page), [15, 20]);
});

test('regression gate catches a changed real weight sum', () => {
  const changed = structuredClone(dataset);
  changed.catalogs[0].items.find((item) => item.id === 'niunja_sogi').biomechanics.weight.front_percent = 31;
  assert.match(validator.validateDataset(changed, inventory).join(), /sum to 100/);
});

test('all discovered real drafts compose without cross-lot duplicates or missing citations', async () => {
  const catalogs = await discoverCatalogFiles(path.join(repositoryRoot, 'knowledge/catalogs'));
  const provenance = await discoverJsonFiles(path.join(repositoryRoot, 'knowledge/provenance'));
  const full = {
    catalogs: await Promise.all(catalogs.map(({ file }) => readJson(file))),
    curricula: [], provenance: await Promise.all(provenance.map((file) => readJson(file))),
  };
  assert.deepEqual(validator.validateDataset(full, inventory), []);
  assert.match(validator.validateDataset(full, inventory, { requireContent: true }).join(), /incomplete/);
});
