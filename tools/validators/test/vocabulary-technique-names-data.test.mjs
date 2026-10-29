import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/vocabulario/vocabulario_nombres_tecnica.json');
const citations = await load('provenance/vocabulario_nombres_tecnica.json');
const initial = await load('catalogs/vocabulario/vocabulario_inicial.json');
const levels = await load('catalogs/vocabulario/vocabulario_niveles_direcciones.json');
const general = await load('catalogs/vocabulario/vocabulario_terminos_generales.json');
const dataset = { catalogs: [initial, levels, general, added], curricula: [], provenance: [
  await load('provenance/vocabulario_inicial.json'),
  await load('provenance/vocabulario_niveles_direcciones.json'),
  await load('provenance/vocabulario_terminos_generales.json'), citations,
] };

test('eleven technique-name rows compose with previous vocabulary and twenty-two citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['chukyo_makgi', 'tulgi', 'yop_makgi', 'ap_makgi',
    'yobap_makgi', 'boosigi', 'golcho', 'miro', 'noollo', 'taerigi', 'momchau']);
  assert.equal(citations.citations.length, 22);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 44);
});

test('each name cites both copies at the observed vocabulary pages without printed folios', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  for (const item of added.items) {
    assert.equal(item.review_status, 'pending_human_review');
    assert.equal(item.citation_ids.length, 2);
    assert.deepEqual(item.citation_ids.map((id) => byId.get(id).content_id), [item.id, item.id]);
    const locations = item.citation_ids.map((id) => {
      const citation = byId.get(id);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.printed_page, null);
      assert.match(citation.section, /^VOCABULARIO: fila /);
      return [citation.source_id, citation.pdf_page];
    });
    assert.deepEqual(locations[0], ['source_teoria_completa_web', 12]);
    assert.equal(locations[1][0], 'source_teoria_ont');
    assert.ok([15, 16].includes(locations[1][1]));
  }
  for (const id of ['taerigi', 'momchau']) {
    const item = added.items.find((entry) => entry.id === id);
    assert.equal(byId.get(item.citation_ids[1]).pdf_page, 16);
  }
});

test('technique names do not absorb generic terms, exercises or existing tools', () => {
  for (const id of ['yop_makgi', 'ap_makgi', 'yobap_makgi']) {
    const item = added.items.find((entry) => entry.id === id);
    assert.match(item.description, /makgi/);
    assert.ok(!item.aliases.length, 'compound names must not become aliases');
  }
  const yop = added.items.find((entry) => entry.id === 'yop_makgi');
  assert.match(yop.description, /saju_makgi/);
  const taerigi = added.items.find((entry) => entry.id === 'taerigi');
  assert.match(taerigi.description, /sonkal/);
  assert.ok(!added.items.some((item) => item.id === 'jirugi' || item.id === 'makgi' || item.id === 'sonkal'
    || item.id === 'naeryo' || item.id === 'sang_san' || item.id === 'chagi' || item.id === 'saju_makgi'),
  'existing or reserved ids must not appear in this batch');
});

test('the duplicated jirugi rows stay excluded and documented instead of forced into one entry', () => {
  assert.ok(!added.items.some((item) => item.id === 'jirugi'));
  const tulgi = added.items.find((item) => item.id === 'tulgi');
  assert.match(tulgi.description, /otra fila de Jirugi/);
  const boosigi = added.items.find((item) => item.id === 'boosigi');
  assert.match(boosigi.description, /primera fila de Jirugi/);
  const taerigi = added.items.find((item) => item.id === 'taerigi');
  assert.match(taerigi.description, /segunda fila de Jirugi/);
});

test('observed wording stays transcribed instead of harmonized', () => {
  const noollo = added.items.find((item) => item.id === 'noollo');
  assert.equal(noollo.translation, 'Descendente para bloqueos');
  assert.match(noollo.description, /Naeryo/);
  const momchau = added.items.find((item) => item.id === 'momchau');
  assert.match(momchau.description, /Sang San/);
  const tulgi = added.items.find((item) => item.id === 'tulgi');
  assert.match(tulgi.description, /sun Sonkut Tulgi/);
  assert.match(tulgi.description, /no se expanden|no se expande/);
});

test('technique-name drafts cannot acquire roles, approval or changed source identity', () => {
  const role = structuredClone(added);
  role.items[0].roles = ['ROLE_ADMIN'];
  assert.match(validator.validateCatalog(role).join(), /additional|unevaluated/);
  const approved = structuredClone(added);
  approved.items[0].review_status = 'approved';
  assert.notEqual(validator.validateCatalog(approved).length, 0);
  const changed = structuredClone(dataset);
  changed.provenance[3].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
});

test('vocabulary coverage report exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.vocabulary, 44);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 44);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
