import path from 'node:path';
import { readJson, repositoryRoot } from '../validators/lib/knowledge.mjs';
import { sqlValue } from './export-draft-sql.mjs';

export function createDraftEditSql(edit) {
  const fields = ['id', 'expected_revision', 'name', 'description', 'reason', 'operator_reference'];
  if (!edit || Array.isArray(edit) || typeof edit !== 'object'
      || Object.keys(edit).length !== fields.length || !fields.every((field) => Object.hasOwn(edit, field))) {
    throw new Error('Draft edit must have exactly the six documented fields');
  }
  if (typeof edit.id !== 'string' || !/^[a-z][a-z0-9]*(_[a-z0-9]+)*$/.test(edit.id) || edit.id !== edit.id.trim()
      || !Number.isSafeInteger(edit.expected_revision) || edit.expected_revision < 0) {
    throw new Error('Invalid canonical ID or expected revision');
  }
  for (const field of ['name', 'description', 'reason', 'operator_reference']) {
    if (typeof edit[field] !== 'string' || !/\S/.test(edit[field])) throw new Error(`Invalid ${field}`);
  }
  const args = fields.map((field) => sqlValue(edit[field])).join(', ');
  return `-- LOCAL DRAFT TEXT EDIT ONLY. No approval/publication.\nBEGIN;\nSELECT revise_content_draft(${args});\nCOMMIT;\n`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.join(repositoryRoot, 'tools/seeders/export-draft-edit-sql.mjs')) {
  try {
    if (process.argv.length !== 4 || process.argv[2] !== '--local-draft-edit') {
      throw new Error('Usage: node tools/seeders/export-draft-edit-sql.mjs --local-draft-edit PATH.json');
    }
    process.stdout.write(createDraftEditSql(await readJson(path.resolve(process.argv[3]))));
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
