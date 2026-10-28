import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/vocabulario/vocabulario_niveles_direcciones.json');
const citations = await load('provenance/vocabulario_niveles_direcciones.json');
const initial = await load('catalogs/vocabulario/vocabulario_inicial.json');
const dataset = { catalogs: [initial, added], curricula: [], provenance: [
  await load('provenance/vocabulario_inicial.json'), citations,
] };

test('seventeen level/direction terms compose with previous vocabulary and thirty-four citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['nopunde', 'kaunde', 'najunde', 'ap', 'dollyo', 'yop',
    'naeryo', 'ollyo', 'bakuro', 'anuro', 'sang_san', 'wi', 'dwi', 'yop_dwi', 'yobap', 'baro', 'bandae']);
  assert.equal(citations.citations.length, 34);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 21);
});

test('each term cites both copies at the observed vocabulary pages without printed folios', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  for (const item of added.items) {
    assert.equal(item.review_status, 'pending_human_review');
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
});

test('the stance-dependent Baro/Bandae inversion is recorded, not unified', () => {
  const baro = added.items.find((item) => item.id === 'baro');
  const bandae = added.items.find((item) => item.id === 'bandae');
  for (const item of [baro, bandae]) {
    assert.match(item.description, /Gunnun Sogi/);
    assert.match(item.description, /Niunja Sogi/);
    assert.match(item.description, /No se unifican|Invierte/);
  }
  assert.match(baro.description, /mismo pie.*invertido|invertido.*mismo pie/s);
  assert.ok(baro.description.includes('mismo pie') && baro.description.includes('pie invertido'));
  assert.ok(bandae.description.includes('mismo pie') && bandae.description.includes('pie invertido'));
});

test('observed translation oddities stay as documented limits instead of silent corrections', () => {
  const dwi = added.items.find((item) => item.id === 'dwi');
  assert.equal(dwi.translation, 'Hacia abajo');
  assert.match(dwi.description, /pendiente de revisión/);
  const naeryo = added.items.find((item) => item.id === 'naeryo');
  assert.match(naeryo.description, /Noollo/);
});

test('vocabulary drafts cannot acquire roles, approval or changed source identity', () => {
  const role = structuredClone(added);
  role.items[0].roles = ['ROLE_ADMIN'];
  assert.match(validator.validateCatalog(role).join(), /additional|unevaluated/);
  const approved = structuredClone(added);
  approved.items[0].review_status = 'approved';
  assert.notEqual(validator.validateCatalog(approved).length, 0);
  const changed = structuredClone(dataset);
  changed.provenance[1].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
});

test('vocabulary coverage report exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.vocabulary, 21);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 21);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
