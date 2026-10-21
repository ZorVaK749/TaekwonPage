import path from 'node:path';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../validators/lib/knowledge.mjs';
import { sqlValue } from './export-draft-sql.mjs';

export async function createCurriculumEditSql(edit) {
  const fields = ['id', 'expected_revision', 'requirements', 'reason', 'operator_reference'];
  if (!edit || Array.isArray(edit) || typeof edit !== 'object' || Object.keys(edit).length !== fields.length
      || !fields.every((field) => Object.hasOwn(edit, field))) throw new Error('Curriculum edit must have exactly five documented fields');
  if (typeof edit.id !== 'string' || !/^gup_(10|[1-9])$/.test(edit.id) || edit.id !== edit.id.trim()
      || !Number.isSafeInteger(edit.expected_revision) || edit.expected_revision < 0) throw new Error('Invalid Gup ID or revision');
  for (const field of ['reason', 'operator_reference']) {
    if (typeof edit[field] !== 'string' || !/\S/.test(edit[field])) throw new Error(`Invalid ${field}`);
  }
  const validator = await createKnowledgeValidator();
  const errors = validator.validateCurriculum({ format_version: 1, id: edit.id, gup: Number(edit.id.slice(4)),
    requirements: edit.requirements, citation_ids: ['citation_payload_validation'], review_status: 'pending_human_review' });
  if (errors.length) throw new Error(errors.join('\n'));
  if (!Object.values(edit.requirements).some((ids) => ids.length)) throw new Error('Curriculum has no requirements');
  const requirements = Object.fromEntries(Object.entries(edit.requirements).map(([key, ids]) => [key, [...ids].sort()]));
  const args = [sqlValue(edit.id), sqlValue(edit.expected_revision), `${sqlValue(JSON.stringify(requirements))}::jsonb`,
    sqlValue(edit.reason), sqlValue(edit.operator_reference)];
  return `-- LOCAL CURRICULUM DRAFT EDIT ONLY. Not school approval.\nBEGIN;\nSELECT revise_curriculum_draft(${args.join(', ')});\nCOMMIT;\n`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.join(repositoryRoot, 'tools/seeders/export-curriculum-edit-sql.mjs')) {
  try {
    if (process.argv.length !== 4 || process.argv[2] !== '--local-curriculum-edit') {
      throw new Error('Usage: node tools/seeders/export-curriculum-edit-sql.mjs --local-curriculum-edit PATH.json');
    }
    process.stdout.write(await createCurriculumEditSql(await readJson(path.resolve(process.argv[3]))));
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
