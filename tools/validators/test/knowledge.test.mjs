import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  checkLocalSources, createKnowledgeValidator, readJson, repositoryRoot,
} from '../lib/knowledge.mjs';

const validator = await createKnowledgeValidator();
const realInventory = await readJson(path.join(repositoryRoot, 'knowledge/sources/inventory.json'));
const cli = fileURLToPath(new URL('../validate-knowledge.mjs', import.meta.url));

// Neutral synthetic fixtures: not martial facts, citations or source approvals.
function inventoryFixture() {
  return {
    format_version: 1,
    sources: [{
      id: 'source_test', file_reference: 'knowledge/sources/pdfs/test.pdf',
      size_bytes: 10, sha256: 'a'.repeat(64), title: null, organization: null,
      author: null, edition: null, language: null, pdf_pages: 10,
      metadata_evidence: 'Synthetic test fixture.', coverage: [],
      review_status: 'pending_human_review', redistribution_status: 'unknown',
      notes: 'Synthetic fixture, not a source document.',
    }],
  };
}

function provenanceFixture() {
  return {
    format_version: 1,
    citations: [{
      id: 'citation_test', content_id: 'content_test', source_id: 'source_test',
      source_sha256: 'a'.repeat(64), pdf_page: 1, printed_page: null,
      section: null, review_status: 'pending_human_review', notes: null,
    }],
  };
}

test('actual four-source inventory conforms to schemas and semantic constraints', () => {
  assert.equal(realInventory.sources.length, 4);
  assert.deepEqual(validator.validateInventory(realInventory), []);
});

test('inventory validation does not mutate or infer metadata', () => {
  const inventory = inventoryFixture();
  const before = structuredClone(inventory);
  assert.deepEqual(validator.validateInventory(inventory), []);
  assert.deepEqual(inventory, before);
});

const invalidInventoryCases = [
  ['empty source list', (d) => { d.sources = []; }],
  ['wrong format', (d) => { d.format_version = 2; }],
  ['unknown root field', (d) => { d.extra = true; }],
  ['unknown source field', (d) => { d.sources[0].unexpected = true; }],
  ['missing required field', (d) => { delete d.sources[0].notes; }],
  ['whitespace-only notes', (d) => { d.sources[0].notes = ' \n\t'; }],
  ['empty title', (d) => { d.sources[0].title = ''; }],
  ['accented ID', (d) => { d.sources[0].id = 'fuente_á'; }],
  ['uppercase ID', (d) => { d.sources[0].id = 'Source_test'; }],
  ['ID with trailing newline', (d) => { d.sources[0].id = 'source_test\n'; }],
  ['double underscore', (d) => { d.sources[0].id = 'source__test'; }],
  ['absolute path', (d) => { d.sources[0].file_reference = 'C:/test.pdf'; }],
  ['traversal', (d) => { d.sources[0].file_reference = 'knowledge/sources/pdfs/../../test.pdf'; }],
  ['backslash traversal', (d) => { d.sources[0].file_reference = 'knowledge/sources/pdfs/..\\test.pdf'; }],
  ['newline in path', (d) => { d.sources[0].file_reference = 'knowledge/sources/pdfs/test\n.pdf'; }],
  ['size coerced from string', (d) => { d.sources[0].size_bytes = '10'; }],
  ['unsafe integer size', (d) => { d.sources[0].size_bytes = 1e20; }],
  ['too small file', (d) => { d.sources[0].size_bytes = 4; }],
  ['invalid hash', (d) => { d.sources[0].sha256 = 'bad'; }],
  ['uppercase hash', (d) => { d.sources[0].sha256 = 'A'.repeat(64); }],
  ['missing evidence', (d) => { d.sources[0].metadata_evidence = null; }],
  ['zero page count', (d) => { d.sources[0].pdf_pages = 0; }],
  ['implicit approval', (d) => { d.sources[0].review_status = 'approved'; }],
  ['implicit redistribution permission', (d) => { d.sources[0].redistribution_status = 'allowed'; }],
  ['unknown coverage field', (d) => { d.sources[0].coverage = [{ topic: 'test', pdf_page_start: 1, pdf_page_end: 1, extra: true }]; }],
  ['coverage reversed', (d) => { d.sources[0].coverage = [{ topic: 'test', pdf_page_start: 5, pdf_page_end: 1 }]; }],
  ['coverage above bounds', (d) => { d.sources[0].coverage = [{ topic: 'test', pdf_page_start: 1, pdf_page_end: 11 }]; }],
  ['coverage without page count', (d) => { d.sources[0].pdf_pages = null; d.sources[0].coverage = [{ topic: 'test', pdf_page_start: 1, pdf_page_end: 2 }]; }],
  ['duplicate ID', (d) => { const s = structuredClone(d.sources[0]); s.file_reference = 'knowledge/sources/pdfs/other.pdf'; s.sha256 = 'b'.repeat(64); d.sources.push(s); }],
  ['case-insensitive duplicate path', (d) => { const s = structuredClone(d.sources[0]); s.id = 'source_other'; s.sha256 = 'b'.repeat(64); s.file_reference = 'knowledge/sources/pdfs/TEST.PDF'; d.sources.push(s); }],
  ['duplicate file identity', (d) => { const s = structuredClone(d.sources[0]); s.id = 'source_other'; s.file_reference = 'knowledge/sources/pdfs/other.pdf'; d.sources.push(s); }],
];

for (const [name, mutate] of invalidInventoryCases) {
  test(`reject inventory: ${name}`, () => {
    const inventory = inventoryFixture();
    mutate(inventory);
    assert.notEqual(validator.validateInventory(inventory).length, 0);
  });
}

test('accept completely unknown bibliographic metadata without fabricating evidence', () => {
  const inventory = inventoryFixture();
  inventory.sources[0].pdf_pages = null;
  inventory.sources[0].metadata_evidence = null;
  assert.deepEqual(validator.validateInventory(inventory), []);
});

test('accept numeric page or section as locator; printed folio is independent', () => {
  const data = provenanceFixture();
  assert.deepEqual(validator.validateProvenance(data, inventoryFixture()), []);
  data.citations[0].pdf_page = null;
  data.citations[0].section = 'Synthetic section';
  data.citations[0].printed_page = 'iv';
  assert.deepEqual(validator.validateProvenance(data, inventoryFixture()), []);
});

const invalidCitationCases = [
  ['empty list', (d) => { d.citations = []; }],
  ['wrong format', (d) => { d.format_version = 2; }],
  ['unknown field', (d) => { d.citations[0].extra = true; }],
  ['missing copy hash', (d) => { delete d.citations[0].source_sha256; }],
  ['missing locator', (d) => { d.citations[0].pdf_page = null; }],
  ['printed page alone is not locator', (d) => { d.citations[0].pdf_page = null; d.citations[0].printed_page = '1'; }],
  ['whitespace section', (d) => { d.citations[0].pdf_page = null; d.citations[0].section = '  '; }],
  ['page zero', (d) => { d.citations[0].pdf_page = 0; }],
  ['fractional page', (d) => { d.citations[0].pdf_page = 1.5; }],
  ['string page', (d) => { d.citations[0].pdf_page = '1'; }],
  ['page beyond copy', (d) => { d.citations[0].pdf_page = 11; }],
  ['unknown source', (d) => { d.citations[0].source_id = 'source_missing'; }],
  ['changed copy', (d) => { d.citations[0].source_sha256 = 'b'.repeat(64); }],
  ['noncanonical content ID', (d) => { d.citations[0].content_id = 'Content Test'; }],
  ['approval not implemented', (d) => { d.citations[0].review_status = 'approved'; }],
  ['duplicate citation ID', (d) => { const c = structuredClone(d.citations[0]); c.pdf_page = 2; d.citations.push(c); }],
  ['duplicate citation location', (d) => { const c = structuredClone(d.citations[0]); c.id = 'citation_other'; d.citations.push(c); }],
];
for (const [name, mutate] of invalidCitationCases) {
  test(`reject citation: ${name}`, () => {
    const data = provenanceFixture();
    mutate(data);
    assert.notEqual(validator.validateProvenance(data, inventoryFixture()).length, 0);
  });
}

test('reject citation pages when inventory page count is unknown', () => {
  const inventory = inventoryFixture();
  inventory.sources[0].pdf_pages = null;
  assert.match(validator.validateProvenance(provenanceFixture(), inventory).join(), /bounds/);
});

test('invalid inventory cannot be used for citations', () => {
  assert.match(validator.validateProvenance(provenanceFixture(), {}).join(), /inventory:/);
});

async function withLocalFixture(run) {
  const temp = await mkdtemp(path.join(process.env.TAEKWONPAGE_TEST_TMP ?? os.tmpdir(), 'taekwonpage-schema-'));
  try {
    const directory = path.join(temp, 'knowledge/sources/pdfs');
    await mkdir(directory, { recursive: true });
    // Deliberately not a complete PDF; this tests identity, not PDF parsing.
    const bytes = Buffer.from('%PDF-synthetic-test');
    const file = path.join(directory, 'test.pdf');
    await writeFile(file, bytes);
    const inventory = inventoryFixture();
    inventory.sources[0].size_bytes = bytes.length;
    inventory.sources[0].sha256 = createHash('sha256').update(bytes).digest('hex');
    const knowledgeRoot = path.join(temp, 'knowledge');
    for (const folder of ['catalogs', 'provenance', 'curricula/gups']) {
      await mkdir(path.join(knowledgeRoot, folder), { recursive: true });
    }
    await writeFile(path.join(knowledgeRoot, 'sources/inventory.json'), JSON.stringify(inventory));
    await run({ temp, directory, file, inventory, knowledgeRoot });
  } finally {
    await rm(temp, { recursive: true, force: true });
  }
}

test('local source identity passes, then same-size changed bytes fail hash', async () => {
  await withLocalFixture(async ({ temp, file, inventory }) => {
    assert.deepEqual(await checkLocalSources(inventory, temp), []);
    await writeFile(file, '%PDF-synthetic-tesX');
    assert.match((await checkLocalSources(inventory, temp)).join(), /SHA-256 mismatch/);
  });
});

test('invalid PDF header, size mismatch and missing files are reported', async () => {
  await withLocalFixture(async ({ temp, file, inventory }) => {
    await writeFile(file, 'NOT!-synthetic-test');
    assert.match((await checkLocalSources(inventory, temp)).join(), /invalid PDF header/);
    await writeFile(file, 'tiny');
    assert.match((await checkLocalSources(inventory, temp)).join(), /size mismatch/);
    await rm(file);
    assert.match((await checkLocalSources(inventory, temp)).join(), /unavailable/);
  });
});

test('nested unregistered PDFs are not silently ignored', async () => {
  await withLocalFixture(async ({ temp, directory, inventory }) => {
    await mkdir(path.join(directory, 'nested'));
    await writeFile(path.join(directory, 'nested/extra.PDF'), '%PDF-extra');
    assert.match((await checkLocalSources(inventory, temp)).join(), /unregistered local PDF/);
  });
});

test('no local source directory is a strict local validation failure', async () => {
  await withLocalFixture(async ({ temp, directory, inventory }) => {
    await rm(directory, { recursive: true });
    assert.match((await checkLocalSources(inventory, temp)).join(), /unavailable/);
  });
});

test('CLI works from outside the repository and reports absence of citations', async () => {
  await withLocalFixture(async ({ temp, knowledgeRoot }) => {
    const result = spawnSync(process.execPath, [cli, '--knowledge-root', knowledgeRoot], { cwd: temp, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /Local PDFs NOT checked/);
    assert.match(result.stdout, /provenance coverage is NOT complete/);
  });
});

test('CLI rejects unknown options and missing values with nonzero status', () => {
  for (const args of [['--invalid'], ['--inventory'], ['--provenance', '--check-local-files']]) {
    const result = spawnSync(process.execPath, [cli, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /FAIL:/);
  }
});

test('CLI validates explicit provenance and detects cross-file duplicate IDs', async () => {
  await withLocalFixture(async ({ temp, inventory, knowledgeRoot }) => {
    const inventoryPath = path.join(temp, 'inventory.json');
    const firstPath = path.join(temp, 'first.json');
    const secondPath = path.join(temp, 'second.json');
    const data = provenanceFixture();
    data.citations[0].source_sha256 = inventory.sources[0].sha256;
    await writeFile(inventoryPath, JSON.stringify(inventory));
    await writeFile(firstPath, JSON.stringify(data));
    const args = [cli, '--knowledge-root', knowledgeRoot, '--inventory', inventoryPath, '--provenance', firstPath];
    let result = spawnSync(process.execPath, args, { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /1 draft citations/);
    data.citations[0].pdf_page = 2;
    await writeFile(secondPath, JSON.stringify(data));
    result = spawnSync(process.execPath, [...args, '--provenance', secondPath], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /duplicate citation ID across files/);
  });
});

test('malformed JSON and invalid UTF-8 fail closed', async () => {
  await withLocalFixture(async ({ temp }) => {
    const bad = path.join(temp, 'bad.json');
    await writeFile(bad, '{broken');
    await assert.rejects(readJson(bad));
    await writeFile(bad, Buffer.from([0xff, 0xfe]));
    await assert.rejects(readJson(bad));
    const result = spawnSync(process.execPath, [cli, '--inventory', bad], { encoding: 'utf8' });
    assert.equal(result.status, 1);
  });
});
