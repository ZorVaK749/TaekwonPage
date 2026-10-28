import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const added = await load('catalogs/teoria/teoria_secciones_cuerpo.json');
const citations = await load('provenance/teoria_secciones_cuerpo.json');
const initial = await load('catalogs/teoria/teoria_inicial.json');
const temario = await load('catalogs/teoria/teoria_temario_inicial.json');
const dataset = { catalogs: [initial, temario, added], curricula: [], provenance: [
  await load('provenance/teoria_inicial.json'), await load('provenance/teoria_temario_inicial.json'), citations,
] };

test('two body-division theory drafts compose with previous theory and four citations', () => {
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(added.items.map((item) => item.id), ['secciones_cuerpo_altura', 'division_lateral_cuerpo']);
  assert.equal(citations.citations.length, 4);
  assert.equal(dataset.catalogs.flatMap((catalog) => catalog.items).length, 7);
});

test('each draft cites both copies at the observed pages without printed folios', () => {
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  const expected = {
    secciones_cuerpo_altura: [['source_teoria_ont', 12], ['source_teoria_completa_web', 10]],
    division_lateral_cuerpo: [['source_teoria_completa_web', 10], ['source_teoria_ont', 13]],
  };
  for (const item of added.items) {
    assert.equal(item.review_status, 'pending_human_review');
    assert.deepEqual(item.citation_ids.map((id) => byId.get(id).content_id), [item.id, item.id]);
    const locations = item.citation_ids.map((id) => {
      const citation = byId.get(id);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.printed_page, null);
      return [citation.source_id, citation.pdf_page];
    });
    assert.deepEqual(locations, expected[item.id]);
  }
});

test('the copy-specific range gap is documented instead of filled from one copy', () => {
  const height = added.items.find((item) => item.id === 'secciones_cuerpo_altura');
  assert.match(height.description, /encima del cuello/);
  assert.match(height.description, /sin esos rangos/);
  const byId = new Map(citations.citations.map((citation) => [citation.id, citation]));
  const webCitation = byId.get(height.citation_ids.find((id) => id.includes('_web_')));
  assert.match(webCitation.notes, /sin el enunciado de rangos/);
  assert.match(webCitation.notes, /sí consta en la otra copia/);
});

test('body division stays documentary instead of becoming targets or exam requirements', () => {
  const lateral = added.items.find((item) => item.id === 'division_lateral_cuerpo');
  assert.match(lateral.description, /No se derivan de aquí puntos vitales, zonas de ataque ni requisitos de examen/);
  const height = added.items.find((item) => item.id === 'secciones_cuerpo_altura');
  assert.match(height.description, /No se derivan zonas objetivo/);
  assert.match(height.description, /vocabulario/);
  assert.ok(!added.items.some((item) => item.id === 'nopunde' || item.id === 'kaunde' || item.id === 'najunde'),
    'existing vocabulary ids must not be duplicated');
});

test('theory drafts cannot acquire roles, approval or changed source identity', () => {
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

test('theory coverage report exposes pending review and an absent curriculum', () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.items_by_type.theory, 7);
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.pending_human_review.content_ids.length, 7);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
