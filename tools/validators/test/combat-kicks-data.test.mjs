import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';
import { createReviewReport } from '../lib/review-report.mjs';

const validator = await createKnowledgeValidator();
const load = (file) => readJson(path.join(repositoryRoot, 'knowledge', file));
const inventory = await load('sources/inventory.json');
const combat = await load('catalogs/combate/combate_inicial.json');
const combatCitations = await load('provenance/combate_inicial.json');
const kicks = await load('catalogs/patadas/patadas_iniciales.json');
const kickCitations = await load('provenance/patadas_iniciales.json');
const tools = await load('catalogs/herramientas/herramientas_iniciales.json');
const toolCitations = await load('provenance/herramientas_iniciales.json');
const dataset = {
  catalogs: [combat, kicks, tools], curricula: [],
  provenance: [combatCitations, kickCitations, toolCitations],
};

// Technical traceability checks; no claim of human approval or martial correctness.
test('combat and kick drafts validate with their registered citations', () => {
  assert.equal(combat.catalog_type, 'combat');
  assert.equal(kicks.catalog_type, 'kick');
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
  assert.deepEqual(combat.items.map((item) => item.id), ['sambo_matsokgi', 'ibo_matsokgi', 'ilbo_matsokgi']);
  assert.deepEqual(kicks.items.map((item) => item.id), ['yopcha_jirugi', 'cha_jirugi', 'i_jung_yopcha_jirugi']);
});

test('every combat and kick item stays pending with located citations', () => {
  const byId = new Map([...combatCitations.citations, ...kickCitations.citations].map((citation) => [citation.id, citation]));
  for (const item of [...combat.items, ...kicks.items]) {
    assert.equal(item.review_status, 'pending_human_review');
    assert.ok(item.citation_ids.length >= 1);
    for (const id of item.citation_ids) {
      const citation = byId.get(id);
      assert.equal(citation.content_id, item.id);
      assert.equal(citation.review_status, 'pending_human_review');
      assert.ok(Number.isInteger(citation.pdf_page));
    }
  }
});

test('two-step sparring is recorded as a single-source divergence, not generalized', () => {
  const ibo = combat.items.find((item) => item.id === 'ibo_matsokgi');
  assert.deepEqual(ibo.citation_ids, ['citation_ibo_matsokgi_ont_p10']);
  const sources = ibo.citation_ids.map((id) => combatCitations.citations.find((citation) => citation.id === id).source_id);
  assert.deepEqual(sources, ['source_teoria_ont']);
  for (const id of ['sambo_matsokgi', 'ilbo_matsokgi']) {
    const item = combat.items.find((entry) => entry.id === id);
    assert.equal(item.citation_ids.length, 2);
  }
});

test('encyclopedia kick evidence keeps observed printed folios and does not infer counts', () => {
  const byId = new Map(kickCitations.citations.map((citation) => [citation.id, citation]));
  assert.equal(byId.get('citation_yopcha_jirugi_enciclopedia_p256').printed_page, '254');
  assert.equal(byId.get('citation_i_jung_yopcha_jirugi_enciclopedia_p257').printed_page, '255');
  for (const citation of kickCitations.citations) {
    assert.equal(citation.source_id, 'source_enciclopedia_taekwondo');
    assert.ok(!/movement|count|paso/i.test(citation.section));
  }
});

test('combat records cannot smuggle step lists or grade requirements', () => {
  const changed = structuredClone(combat);
  changed.items[0].steps = [{ step_number: 1 }];
  assert.match(validator.validateCatalog(changed).join(), /unevaluated|additional/);
  const withGup = structuredClone(combat);
  withGup.items[0].required_gup = 10;
  assert.match(validator.validateCatalog(withGup).join(), /unevaluated|additional/);
});

test('new combat and kick drafts still cannot satisfy the presence gate', () => {
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
});

test('foot tools and the new combat/kick drafts compose into one valid draft set', async () => {
  const report = createReviewReport({ inventory, ...dataset }, { contentReferencesChecked: true });
  assert.equal(report.counts.curricula, 0);
  assert.equal(report.counts.content_items, combat.items.length + kicks.items.length + tools.items.length);
  assert.deepEqual(report.items_by_type.combat, 3);
  assert.deepEqual(report.items_by_type.kick, 3);
  assert.equal(report.items_by_type.body_tool, 10);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
});
