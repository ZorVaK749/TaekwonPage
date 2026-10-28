import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/herramientas/herramientas_cuerpo.json');
const citations = await load('provenance/herramientas_cuerpo.json');
const initial = await load('catalogs/herramientas/herramientas_iniciales.json');
const dataset = { catalogs: [initial, added], curricula: [], provenance: [
  await load('provenance/herramientas_iniciales.json'), citations,
] };

test('fourteen body-part terms compose with the initial body_tool catalog and twenty-three citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['dung_joomuk', 'sonbadak', 'sonkal_dung', 'sonkut',
    'opun_sonkut', 'sun_sonkut', 'dwijibun_sonkut', 'bandal_son', 'palkup', 'baldung', 'balkaldung', 'balkut',
    'mori', 'kyong_gol']);
  assert.equal(citations.citations.length, 23);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 24);
});

test('five hand rows absent from the WEB table cite only ONT at the observed page', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  const ontopOnly = ['dung_joomuk', 'sonbadak', 'sonkal_dung', 'sonkut', 'opun_sonkut'];
  for (const id of ontopOnly) {
    const item = added.items.find((entry) => entry.id === id);
    assert.equal(item.review_status, 'pending_human_review');
    assert.equal(item.citation_ids.length, 1);
    const citation = byId.get(item.citation_ids[0]);
    assert.equal(citation.content_id, id);
    assert.equal(citation.source_id, 'source_teoria_ont');
    assert.equal(citation.pdf_page, 14);
    assert.equal(citation.printed_page, null);
    assert.equal(citation.review_status, 'pending_human_review');
    assert.match(citation.section, /^VOCABULARIO: fila /);
  }
});

test('the remaining nine rows cite both copies at their observed pages without printed folios', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  const ontopPageById = { sun_sonkut: 14, dwijibun_sonkut: 15, bandal_son: 15, palkup: 15, baldung: 15,
    balkaldung: 15, balkut: 15, mori: 15, kyong_gol: 15 };
  for (const [id, ontPage] of Object.entries(ontopPageById)) {
    const item = added.items.find((entry) => entry.id === id);
    assert.equal(item.review_status, 'pending_human_review');
    assert.deepEqual(item.citation_ids.map((citationId) => byId.get(citationId).content_id), [id, id]);
    const locations = item.citation_ids.map((citationId) => {
      const citation = byId.get(citationId);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.printed_page, null);
      assert.match(citation.section, /^VOCABULARIO: fila /);
      return [citation.source_id, citation.pdf_page];
    });
    assert.deepEqual(locations, [['source_teoria_completa_web', 12], ['source_teoria_ont', ontPage]]);
  }
});

test('excluded and overlapping rows stay out of the catalog instead of being merged', () => {
  const ids = added.items.map((item) => item.id);
  assert.ok(!ids.includes('dwichook'), 'Dwichook must remain excluded until TKD-003');
  assert.ok(!ids.includes('sonkal'), 'existing canonical id must not be duplicated');
  assert.ok(!ids.includes('ap_joomuk') && !ids.includes('palmok') && !ids.includes('bakat_palmok')
    && !ids.includes('an_palmok') && !ids.includes('apkumchi') && !ids.includes('balkal')
    && !ids.includes('moorup'), 'rows covered by other catalogs must not be re-added');
  const bandalSon = added.items.find((item) => item.id === 'bandal_son');
  assert.match(bandalSon.description, /Arca de la mano/);
  assert.match(bandalSon.description, /sin corregirla/);
});

test('body-part drafts cannot acquire roles, approval or changed source identity', () => {
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

test('body-tool coverage report exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.body_tool, 24);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 24);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
