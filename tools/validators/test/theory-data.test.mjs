import assert from 'node:assert/strict';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../lib/knowledge.mjs';

const validator = await createKnowledgeValidator();
const inventory = await readJson(path.join(repositoryRoot, 'knowledge/sources/inventory.json'));
const catalog = await readJson(path.join(repositoryRoot, 'knowledge/catalogs/teoria/teoria_inicial.json'));
const provenance = await readJson(path.join(repositoryRoot, 'knowledge/provenance/teoria_inicial.json'));
const dataset = { catalogs: [catalog], curricula: [], provenance: [provenance] };

// These tests check technical traceability of real drafts, NOT martial truth.
test('initial real theory lot validates without distributing or requiring PDF bytes', () => {
  assert.equal(catalog.catalog_type, 'theory');
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('initial lot stays pending and links each of its three items to both observed copies', () => {
  assert.equal(catalog.items.length, 3);
  assert.equal(provenance.citations.length, 6);
  const citations = new Map(provenance.citations.map((citation) => [citation.id, citation]));
  for (const item of catalog.items) {
    assert.equal(item.review_status, 'pending_human_review');
    const linked = item.citation_ids.map((id) => citations.get(id));
    assert.deepEqual(linked.map((citation) => citation.source_id).sort(), [
      'source_teoria_completa_web', 'source_teoria_ont',
    ]);
    for (const citation of linked) {
      assert.equal(citation.review_status, 'pending_human_review');
      assert.equal(citation.content_id, item.id);
      assert.ok([2, 6].includes(citation.pdf_page));
      assert.equal(citation.printed_page, null);
    }
  }
});

test('initial theory lot cannot pass foundation presence gate without a curriculum', () => {
  assert.match(validator.validateDataset(dataset, inventory, { requireContent: true }).join(), /incomplete/);
});

test('tampered real citation cannot pass against its registered PDF identity', () => {
  const changed = structuredClone(dataset);
  changed.provenance[0].citations[0].source_sha256 = '0'.repeat(64);
  assert.match(validator.validateDataset(changed, inventory).join(), /SHA-256/);
});

test('default CLI discovers and validates real theory/citations, without requiring a curriculum', () => {
  const cli = fileURLToPath(new URL('../validate-knowledge.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [cli], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /references checked against supplied drafts/);
  assert.match(result.stdout, /human approval are NOT validated/);
});
