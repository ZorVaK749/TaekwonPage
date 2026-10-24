import assert from 'node:assert/strict';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { createCitationEditSql } from '../../seeders/export-citation-edit-sql.mjs';
import { createImportFixture } from '../fixtures/import-dataset.mjs';
import { repositoryRoot } from '../lib/knowledge.mjs';

function fixture() {
  const { dataset, inventory } = createImportFixture();
  const citation = dataset.provenance[0].citations[0];
  return { inventory, edit: { id: citation.content_id, expected_revision: 0, citations: [citation],
    reason: "Synthetic ' reason $$", operator_reference: 'Unverified test operator' } };
}

test('citation SQL preserves source/hash and independent PDF/printed locators without mutating payload', async () => {
  const { edit, inventory } = fixture();
  edit.citations[0].pdf_page = 3;
  edit.citations[0].printed_page = 'Observed folio X';
  const before = structuredClone(edit);
  const sql = await createCitationEditSql(edit, inventory);
  assert.match(sql, /SELECT revise_content_citations\(/);
  assert.ok(sql.includes('"pdf_page":3'));
  assert.ok(sql.includes('"printed_page":"Observed folio X"'));
  assert.ok(sql.includes('a'.repeat(64)));
  assert.deepEqual(edit, before);
});

test('section-only evidence remains valid and citation ordering is deterministic', async () => {
  const { edit, inventory } = fixture();
  edit.citations[0].id = 'citation_z';
  edit.citations.push({ ...edit.citations[0], id: 'citation_a', pdf_page: null, section: 'Synthetic section' });
  const sql = await createCitationEditSql(edit, inventory);
  assert.ok(sql.indexOf('citation_a') < sql.indexOf('citation_z'));
  assert.deepEqual(edit.citations.map((c) => c.id), ['citation_z', 'citation_a']);
});

test('unknown sources, mismatching hashes and out-of-bounds locators fail before SQL generation', async () => {
  for (const change of [{ source_id: 'missing_source' }, { source_sha256: '0'.repeat(64) }, { pdf_page: 11 },
    { pdf_page: null, section: null }, { printed_page: ' ' }, { file_reference: 'not_permitted.pdf' }]) {
    const { edit, inventory } = fixture();
    Object.assign(edit.citations[0], change);
    await assert.rejects(createCitationEditSql(edit, inventory));
  }
});

test('citation payload cannot transfer ownership, approve content or leave it uncited', async () => {
  for (const mutate of [(e) => { e.citations = []; }, (e) => { e.citations[0].content_id = 'another_entry'; },
    (e) => { e.citations[0].review_status = 'approved'; }, (e) => { e.review_status = 'approved'; }]) {
    const { edit, inventory } = fixture();
    mutate(edit);
    await assert.rejects(createCitationEditSql(edit, inventory));
  }
});

test('citation identities/locations must be unique, with explicit actor/reason/revision', async () => {
  for (const mutate of [(e) => { e.citations.push(structuredClone(e.citations[0])); },
    (e) => { e.citations.push({ ...e.citations[0], id: 'citation_different_id' }); },
    (e) => { e.reason = ' '; }, (e) => { e.operator_reference = null; }, (e) => { e.expected_revision = '0'; }]) {
    const { edit, inventory } = fixture();
    mutate(edit);
    await assert.rejects(createCitationEditSql(edit, inventory));
  }
});

test('citation CLI refuses missing consent or payload without producing SQL', () => {
  const script = path.join(repositoryRoot, 'tools/seeders/export-citation-edit-sql.mjs');
  for (const args of [[], ['--local-citation-edit', 'missing-synthetic-citation-edit.json']]) {
    const result = spawnSync(process.execPath, [script, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
  }
});
