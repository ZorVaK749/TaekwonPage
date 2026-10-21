import path from 'node:path';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../validators/lib/knowledge.mjs';
import { sqlValue } from './export-draft-sql.mjs';

export async function createDetailEditSql(edit) {
  const fields = ['id', 'expected_revision', 'content_type', 'details', 'reason', 'operator_reference'];
  if (!edit || Array.isArray(edit) || typeof edit !== 'object' || Object.keys(edit).length !== fields.length
      || !fields.every((field) => Object.hasOwn(edit, field))) throw new Error('Detail edit must have exactly six documented fields');
  if (typeof edit.id !== 'string' || !/^[a-z][a-z0-9]*(_[a-z0-9]+)*$/.test(edit.id) || edit.id !== edit.id.trim()
      || !Number.isSafeInteger(edit.expected_revision) || edit.expected_revision < 0) throw new Error('Invalid ID or revision');
  for (const field of ['reason', 'operator_reference']) {
    if (typeof edit[field] !== 'string' || !/\S/.test(edit[field])) throw new Error(`Invalid ${field}`);
  }
  const keys = edit.content_type === 'position'
    ? ['front_percent', 'rear_percent', 'front_rotation_deg', 'rear_rotation_deg']
    : edit.content_type === 'vocabulary' ? ['translation', 'aliases'] : null;
  const d = edit.details;
  if (!keys || !d || Array.isArray(d) || typeof d !== 'object' || Object.keys(d).length !== keys.length
      || !keys.every((key) => Object.hasOwn(d, key))) throw new Error('Unsupported type or incomplete detail fields');
  const item = { id: edit.id, name: 'Draft payload validation', description: 'Technical validation only.',
    citation_ids: ['citation_payload_validation'], review_status: 'pending_human_review' };
  if (edit.content_type === 'position') {
    item.biomechanics = {
      weight: d.front_percent === null && d.rear_percent === null ? null
        : { front_percent: d.front_percent, rear_percent: d.rear_percent },
      front_foot: d.front_rotation_deg === null ? null : { rotation_deg: d.front_rotation_deg },
      rear_foot: d.rear_rotation_deg === null ? null : { rotation_deg: d.rear_rotation_deg },
    };
    if (d.front_percent !== null && d.rear_percent !== null && Math.abs(d.front_percent + d.rear_percent - 100) > 1e-9) {
      throw new Error('Weights must sum to 100');
    }
  } else {
    Object.assign(item, d);
  }
  const validator = await createKnowledgeValidator();
  const errors = validator.validateCatalog({ format_version: 1, catalog_type: edit.content_type, items: [item] });
  if (errors.length) throw new Error(errors.join('\n'));
  const args = [sqlValue(edit.id), sqlValue(edit.expected_revision), sqlValue(edit.content_type),
    `${sqlValue(JSON.stringify(d))}::jsonb`, sqlValue(edit.reason), sqlValue(edit.operator_reference)];
  return `-- LOCAL CATALOG DETAIL EDIT ONLY. No martial approval.\nBEGIN;\nSELECT revise_catalog_details(${args.join(', ')});\nCOMMIT;\n`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.join(repositoryRoot, 'tools/seeders/export-detail-edit-sql.mjs')) {
  try {
    if (process.argv.length !== 4 || process.argv[2] !== '--local-detail-edit') {
      throw new Error('Usage: node tools/seeders/export-detail-edit-sql.mjs --local-detail-edit PATH.json');
    }
    process.stdout.write(await createDetailEditSql(await readJson(path.resolve(process.argv[3]))));
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
