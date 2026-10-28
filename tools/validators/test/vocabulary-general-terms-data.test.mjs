import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/vocabulario/vocabulario_terminos_generales.json');
const citations = await load('provenance/vocabulario_terminos_generales.json');
const initial = await load('catalogs/vocabulario/vocabulario_inicial.json');
const levels = await load('catalogs/vocabulario/vocabulario_niveles_direcciones.json');
const dataset = { catalogs: [initial, levels, added], curricula: [], provenance: [
  await load('provenance/vocabulario_inicial.json'),
  await load('provenance/vocabulario_niveles_direcciones.json'), citations,
] };

test('twelve general terms compose with previous vocabulary and twenty-four citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['jumbi_sogi', 'chagi', 'twigi', 'twimyo', 'bande', 'sogi',
    'so', 'makgi', 'opun', 'dwijibun', 'kyocha', 'jeja']);
  assert.equal(citations.citations.length, 24);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 33);
});

test('each term cites both copies at the observed vocabulary pages without printed folios', () => {
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
    const [, ontPage] = locations[1];
    assert.deepEqual(locations, [['source_teoria_completa_web', 11], ['source_teoria_ont', ontPage]]);
    assert.ok([13, 14].includes(ontPage));
  }
  const jumbi = added.items.find((item) => item.id === 'jumbi_sogi');
  assert.equal(byId.get(jumbi.citation_ids[1]).pdf_page, 13);
});

test('generic terms do not absorb existing concrete entries or roles', () => {
  const jumbi = added.items.find((item) => item.id === 'jumbi_sogi');
  assert.match(jumbi.description, /narani_junbi_sogi/);
  const makgi = added.items.find((item) => item.id === 'makgi');
  assert.match(makgi.description, /saju_makgi/);
  const jeja = added.items.find((item) => item.id === 'jeja');
  assert.match(jeja.description, /no un rol/);
  assert.ok(!added.items.some((item) => item.id === 'charyot_sogi' || item.id === 'gunnun_sogi'
    || item.id === 'narani_junbi_sogi' || item.id === 'saju_makgi'), 'existing ids must not be duplicated');
});

test('observed oddities stay as documented limits instead of silent corrections', () => {
  const dwijibun = added.items.find((item) => item.id === 'dwijibun');
  assert.equal(dwijibun.translation, 'Palma hacai arriba');
  assert.match(dwijibun.description, /hacai/);
  assert.match(dwijibun.description, /errata/);
  const twigi = added.items.find((item) => item.id === 'twigi');
  assert.match(twigi.description, /Twimyo/);
});

test('general-term drafts cannot acquire roles, approval or changed source identity', () => {
  const role = structuredClone(added);
  role.items[0].roles = ['ROLE_ADMIN'];
  assert.match(validator.validateCatalog(role).join(), /additional|unevaluated/);
  const approved = structuredClone(added);
  approved.items[0].review_status = 'approved';
  assert.notEqual(validator.validateCatalog(approved).length, 0);
  const changed = structuredClone(dataset);
  changed.provenance[2].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
});

test('vocabulary coverage report exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.vocabulary, 33);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 33);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
