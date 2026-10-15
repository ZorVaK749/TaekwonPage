import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { createKnowledgeValidator } from '../lib/knowledge.mjs';
import { discoverCatalogFiles, discoverJsonFiles } from '../lib/content-files.mjs';

const validator = await createKnowledgeValidator();
const types = ['position', 'theory', 'tul', 'vocabulary', 'body_tool', 'kick', 'combat'];
const cli = fileURLToPath(new URL('../validate-knowledge.mjs', import.meta.url));

// Entirely synthetic technical fixtures: not martial content or curriculum.
function fixture() {
  const inventory = {
    format_version: 1,
    sources: [{
      id: 'source_fixture', file_reference: 'knowledge/sources/pdfs/fixture.pdf',
      size_bytes: 10, sha256: 'a'.repeat(64), title: null, author: null,
      organization: null, edition: null, language: null, pdf_pages: 10,
      metadata_evidence: 'Synthetic fixture.', coverage: [], notes: 'Test only.',
      review_status: 'pending_human_review', redistribution_status: 'unknown',
    }],
  };
  const catalogs = types.map((type) => {
    const item = {
      id: `fixture_${type}`, name: `Synthetic ${type}`, description: 'Test only; not martial information.',
      citation_ids: [`citation_${type}`], review_status: 'pending_human_review',
    };
    if (type === 'position') {
      item.biomechanics = {
        weight: { front_percent: 40, rear_percent: 60 },
        front_foot: { rotation_deg: 0 }, rear_foot: { rotation_deg: 90 },
      };
    }
    if (type === 'tul') {
      item.movement_count = 2;
      item.initial_position_id = 'fixture_position';
      item.sequence_complete = true;
      item.steps = [1, 2].map((number) => ({
        step_number: number, position_id: 'fixture_position',
        description: 'Synthetic step, not a martial sequence.', citation_ids: ['citation_tul'],
      }));
    }
    if (type === 'vocabulary') {
      item.translation = 'Synthetic translation.';
      item.aliases = [];
    }
    return { format_version: 1, catalog_type: type, items: [item] };
  });
  const curricula = [{
    format_version: 1, id: 'gup_10', gup: 10,
    requirements: Object.fromEntries(types.map((type) => [`${type}_ids`, [`fixture_${type}`]])),
    citation_ids: ['citation_curriculum'], review_status: 'pending_human_review',
  }];
  const citations = [...types, 'curriculum'].map((type) => ({
    id: `citation_${type}`, content_id: type === 'curriculum' ? 'gup_10' : `fixture_${type}`,
    source_id: 'source_fixture', source_sha256: 'a'.repeat(64), pdf_page: 1,
    printed_page: null, section: null, notes: 'Test only.', review_status: 'pending_human_review',
  }));
  return { inventory, dataset: { catalogs, curricula, provenance: [{ format_version: 1, citations }] } };
}

const item = (dataset, type) => dataset.catalogs.find((catalog) => catalog.catalog_type === type).items[0];

test('all seven catalog types and ID-only Gup validate as a linked synthetic dataset', () => {
  const { dataset, inventory } = fixture();
  const before = structuredClone(dataset);
  assert.deepEqual(validator.validateDataset(dataset, inventory, { requireContent: true }), []);
  assert.deepEqual(dataset, before);
});

for (const type of types) {
  test(`${type} schema rejects unknown fields and missing citations`, () => {
    const { dataset } = fixture();
    const catalog = dataset.catalogs.find((entry) => entry.catalog_type === type);
    assert.deepEqual(validator.validateCatalog(catalog), []);
    catalog.items[0].unexpected = 'not allowed';
    assert.notEqual(validator.validateCatalog(catalog).length, 0);
    delete catalog.items[0].unexpected;
    catalog.items[0].citation_ids = [];
    assert.notEqual(validator.validateCatalog(catalog).length, 0);
  });
}

const invalidCases = [
  ['empty catalog', (d) => { d.catalogs[0].items = []; }, /min|fewer/],
  ['unknown catalog type', (d) => { d.catalogs[0].catalog_type = 'invented'; }, /allowed/],
  ['missing content description', (d) => { delete item(d, 'theory').description; }, /required/],
  ['content with whitespace name', (d) => { item(d, 'kick').name = ' '; }, /pattern/],
  ['noncanonical content ID', (d) => { item(d, 'combat').id = 'Bad ID'; }, /pattern/],
  ['duplicate ID within catalog', (d) => { d.catalogs[0].items.push(structuredClone(d.catalogs[0].items[0])); }, /duplicate content ID/],
  ['duplicate ID across categories', (d) => { item(d, 'kick').id = 'fixture_theory'; }, /duplicate content ID/],
  ['missing curriculum group', (d) => { delete d.curricula[0].requirements.combat_ids; }, /required/],
  ['curriculum embeds definitions', (d) => { d.curricula[0].requirements.theory_ids = [{ id: 'fixture_theory', text: 'not an ID' }]; }, /string/],
  ['curriculum references missing content', (d) => { d.curricula[0].requirements.kick_ids = ['missing_kick']; }, /missing or wrong-type/],
  ['curriculum references wrong category', (d) => { d.curricula[0].requirements.position_ids = ['fixture_theory']; }, /wrong-type/],
  ['duplicate curriculum reference', (d) => { d.curricula[0].requirements.theory_ids.push('fixture_theory'); }, /duplicate/],
  ['all curriculum requirements empty', (d) => { for (const field of Object.keys(d.curricula[0].requirements)) d.curricula[0].requirements[field] = []; }, /no requirements/],
  ['grade and ID mismatch', (d) => { d.curricula[0].gup = 9; }, /ID must match/],
  ['grade outside Gup range', (d) => { d.curricula[0].gup = 11; }, /<= 10/],
  ['Dan is not a numeric Gup', (d) => { d.curricula[0].gup = 'I Dan'; }, /integer/],
  ['curriculum is not approved by schema', (d) => { d.curricula[0].review_status = 'approved'; }, /constant/],
  ['content is not approved by schema', (d) => { item(d, 'theory').review_status = 'approved'; }, /constant/],
  ['missing citation', (d) => { item(d, 'theory').citation_ids = ['citation_missing']; }, /unknown citation/],
  ['citation for another content', (d) => { item(d, 'theory').citation_ids = ['citation_kick']; }, /belongs to another/],
  ['citation refers to absent content', (d) => { d.provenance[0].citations[0].content_id = 'absent'; }, /unknown content_id/],
  ['citation for wrong PDF bytes', (d) => { d.provenance[0].citations[0].source_sha256 = 'b'.repeat(64); }, /SHA-256/],
  ['orphan citation', (d) => { const c = structuredClone(d.provenance[0].citations[0]); c.id = 'citation_unused'; c.pdf_page = 2; d.provenance[0].citations.push(c); }, /not linked/],
  ['duplicate citation across files', (d) => { d.provenance.push(structuredClone(d.provenance[0])); }, /duplicate citation ID across files/],
  ['weight sum invalid', (d) => { item(d, 'position').biomechanics.weight.front_percent = 41; }, /sum to 100/],
  ['weight below zero', (d) => { item(d, 'position').biomechanics.weight.front_percent = -1; }, />= 0/],
  ['weight above 100', (d) => { item(d, 'position').biomechanics.weight.front_percent = 101; }, /<= 100/],
  ['foot rotation negative', (d) => { item(d, 'position').biomechanics.front_foot.rotation_deg = -1; }, />= 0/],
  ['foot rotation at excluded 360', (d) => { item(d, 'position').biomechanics.rear_foot.rotation_deg = 360; }, /< 360/],
  ['foot rotation coerced from string', (d) => { item(d, 'position').biomechanics.rear_foot.rotation_deg = '90'; }, /number/],
  ['coordinates not yet defined', (d) => { item(d, 'position').biomechanics.front_foot.x = 1; }, /additional/],
  ['missing initial position reference', (d) => { item(d, 'tul').initial_position_id = 'missing'; }, /missing or wrong-type/],
  ['wrong-type step position', (d) => { item(d, 'tul').steps[0].position_id = 'fixture_kick'; }, /wrong-type/],
  ['step lacks provenance', (d) => { item(d, 'tul').steps[0].citation_ids = []; }, /fewer/],
  ['step uses another content citation', (d) => { item(d, 'tul').steps[0].citation_ids = ['citation_theory']; }, /belongs to another/],
  ['duplicate step numbers', (d) => { item(d, 'tul').steps[1].step_number = 1; }, /strictly increasing/],
  ['steps out of order', (d) => { item(d, 'tul').steps.reverse(); }, /strictly increasing/],
  ['step exceeds movement count', (d) => { item(d, 'tul').steps[1].step_number = 3; }, /exceeds declared/],
  ['complete sequence missing steps', (d) => { item(d, 'tul').steps.pop(); }, /complete sequence/],
  ['complete sequence unknown total', (d) => { item(d, 'tul').movement_count = null; }, /complete sequence/],
  ['complete sequence unknown initial position', (d) => { item(d, 'tul').initial_position_id = null; }, /complete sequence/],
];

for (const [name, mutate, expected] of invalidCases) {
  test(`reject linked dataset: ${name}`, () => {
    const { dataset, inventory } = fixture();
    mutate(dataset);
    assert.match(validator.validateDataset(dataset, inventory).join('\n'), expected);
  });
}

test('unknown biomechanics and incomplete Tul drafts are explicit, not auto-filled', () => {
  const { dataset, inventory } = fixture();
  item(dataset, 'position').biomechanics = null;
  Object.assign(item(dataset, 'tul'), {
    movement_count: null, initial_position_id: null, sequence_complete: false, steps: [],
  });
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('partial biomechanical observations and decimal percentages are supported', () => {
  const { dataset, inventory } = fixture();
  const biomechanics = item(dataset, 'position').biomechanics;
  biomechanics.front_foot = null;
  biomechanics.weight = { front_percent: 30.1, rear_percent: 69.9 };
  assert.deepEqual(validator.validateDataset(dataset, inventory), []);
});

test('empty workspace is not a completed content foundation', () => {
  const { inventory } = fixture();
  const empty = { catalogs: [], curricula: [], provenance: [] };
  assert.deepEqual(validator.validateDataset(empty, inventory), []);
  assert.match(validator.validateDataset(empty, inventory, { requireContent: true }).join(), /incomplete/);
  assert.match(validator.validateDataset(null, inventory).join(), /arrays/);
});

async function withTemporaryDirectory(run) {
  const directory = await mkdtemp(path.join(process.env.TAEKWONPAGE_TEST_TMP ?? os.tmpdir(), 'taekwonpage-content-'));
  try { await run(directory); } finally { await rm(directory, { recursive: true, force: true }); }
}

async function createEmptyKnowledgeRoot(directory) {
  const root = path.join(directory, 'knowledge');
  for (const folder of ['sources', 'catalogs', 'curricula/gups', 'provenance']) {
    await mkdir(path.join(root, folder), { recursive: true });
  }
  return root;
}

test('recursive discovery catches uppercase JSON and identifies catalog directory', async () => {
  await withTemporaryDirectory(async (directory) => {
    await mkdir(path.join(directory, 'teoria/nested'), { recursive: true });
    const file = path.join(directory, 'teoria/nested/test.JSON');
    await writeFile(file, '{}');
    await writeFile(path.join(directory, '.gitkeep'), '');
    assert.deepEqual(await discoverCatalogFiles(directory), [{ file, type: 'theory' }]);
    assert.deepEqual(await discoverJsonFiles(directory), [file]);
    await writeFile(path.join(directory, 'unclassified.json'), '{}');
    await assert.rejects(discoverCatalogFiles(directory), /Unknown catalog directory/);
  });
});

test('CLI validates full synthetic content then rejects broken typed references', async () => {
  await withTemporaryDirectory(async (directory) => {
    const { inventory, dataset } = fixture();
    const root = await createEmptyKnowledgeRoot(directory);
    const args = [cli, '--require-content', '--knowledge-root', root];
    for (const [name, data] of [['inventory', inventory], ['provenance', dataset.provenance[0]], ['curriculum', dataset.curricula[0]]]) {
      const file = path.join(directory, `${name}.json`);
      await writeFile(file, JSON.stringify(data));
      args.push(`--${name}`, file);
    }
    for (const catalog of dataset.catalogs) {
      const file = path.join(directory, `${catalog.catalog_type}.json`);
      await writeFile(file, JSON.stringify(catalog));
      args.push('--catalog', file);
    }
    let result = spawnSync(process.execPath, args, { cwd: directory, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /references checked/);
    dataset.curricula[0].requirements.theory_ids = ['fixture_kick'];
    await writeFile(path.join(directory, 'curriculum.json'), JSON.stringify(dataset.curricula[0]));
    result = spawnSync(process.execPath, args, { cwd: directory, encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /wrong-type theory reference/);
  });
});

test('CLI strict mode fails on isolated empty content, and path flags require values', async () => {
  await withTemporaryDirectory(async (directory) => {
    const root = await createEmptyKnowledgeRoot(directory);
    const { inventory } = fixture();
    await writeFile(path.join(root, 'sources/inventory.json'), JSON.stringify(inventory));
    const result = spawnSync(process.execPath, [cli, '--knowledge-root', root, '--require-content'], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /foundation incomplete/);
  });
  for (const flag of ['--catalog', '--curriculum', '--knowledge-root']) {
    const result = spawnSync(process.execPath, [cli, flag], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Missing path/);
  }
});

test('CLI auto-discovers isolated files and rejects catalog/directory mismatches', async () => {
  await withTemporaryDirectory(async (directory) => {
    const root = await createEmptyKnowledgeRoot(directory);
    const { inventory, dataset } = fixture();
    await writeFile(path.join(root, 'sources/inventory.json'), JSON.stringify(inventory));
    await writeFile(path.join(root, 'provenance/fixture.json'), JSON.stringify(dataset.provenance[0]));
    await writeFile(path.join(root, 'curricula/gups/fixture.json'), JSON.stringify(dataset.curricula[0]));
    const directories = ['posiciones', 'teoria', 'tuls', 'vocabulario', 'herramientas', 'patadas', 'combate'];
    for (const [index, folder] of directories.entries()) {
      await mkdir(path.join(root, 'catalogs', folder));
      await writeFile(path.join(root, 'catalogs', folder, 'fixture.json'), JSON.stringify(dataset.catalogs[index]));
    }
    const args = [cli, '--knowledge-root', root, '--require-content'];
    let result = spawnSync(process.execPath, args, { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    await writeFile(path.join(root, 'catalogs/posiciones/fixture.json'), JSON.stringify(dataset.catalogs[1]));
    result = spawnSync(process.execPath, args, { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /catalog_type must match directory/);
  });
});
