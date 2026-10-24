import path from 'node:path';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../validators/lib/knowledge.mjs';
import { sqlValue } from './export-draft-sql.mjs';

export async function createCitationEditSql(edit, inventory) {
  const fields = ['id', 'expected_revision', 'citations', 'reason', 'operator_reference'];
  if (!edit || Array.isArray(edit) || typeof edit !== 'object' || Object.keys(edit).length !== fields.length
      || !fields.every((field) => Object.hasOwn(edit, field))) throw new Error('Citation edit must have exactly five documented fields');
  if (typeof edit.id !== 'string' || !/^[a-z][a-z0-9]*(_[a-z0-9]+)*$/.test(edit.id) || edit.id !== edit.id.trim()
      || !Number.isSafeInteger(edit.expected_revision) || edit.expected_revision < 0) throw new Error('Invalid ID or revision');
  for (const field of ['reason', 'operator_reference']) {
    if (typeof edit[field] !== 'string' || !/\S/.test(edit[field])) throw new Error(`Invalid ${field}`);
  }
  const sources = inventory ?? await readJson(path.join(repositoryRoot, 'knowledge/sources/inventory.json'));
  const validator = await createKnowledgeValidator();
  const errors = validator.validateProvenance({ format_version: 1, citations: edit.citations }, sources);
  if (errors.length) throw new Error(errors.join('\n'));
  if (edit.citations.some((citation) => citation.content_id !== edit.id)) throw new Error('Citations must belong to the edited entry');
  if (edit.citations.some((citation) => citation.pdf_page !== null && citation.pdf_page > 2147483647)) throw new Error('Page exceeds database integer range');
  const citations = [...edit.citations].sort((a, b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  const args = [sqlValue(edit.id), sqlValue(edit.expected_revision), `${sqlValue(JSON.stringify(citations))}::jsonb`,
    sqlValue(edit.reason), sqlValue(edit.operator_reference)];
  return `-- LOCAL CITATION DRAFT EDIT ONLY. No approval or redistribution rights.\nBEGIN;\nSELECT revise_content_citations(${args.join(', ')});\nCOMMIT;\n`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.join(repositoryRoot, 'tools/seeders/export-citation-edit-sql.mjs')) {
  try {
    if (process.argv.length !== 4 || process.argv[2] !== '--local-citation-edit') throw new Error('Usage: node tools/seeders/export-citation-edit-sql.mjs --local-citation-edit PATH.json');
    process.stdout.write(await createCitationEditSql(await readJson(path.resolve(process.argv[3]))));
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
