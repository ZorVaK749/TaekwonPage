// Called only by database tests. Never adds files to knowledge/curricula.
import { createImportFixture } from './fixtures/import-dataset.mjs';
import { createDraftSql } from '../seeders/export-draft-sql.mjs';
import { createDraftEditSql } from '../seeders/export-draft-edit-sql.mjs';
import { createCurriculumEditSql } from '../seeders/export-curriculum-edit-sql.mjs';
import { createDetailEditSql } from '../seeders/export-detail-edit-sql.mjs';

const { dataset, inventory } = createImportFixture();
const mode = process.argv[2];
if (mode === 'conflict-name') {
  dataset.catalogs[0].items[0].name = 'Changed fixture';
  // Written earlier in the transaction; must disappear if a later conflict aborts.
  inventory.sources.unshift({ ...inventory.sources[0], id: 'source_rollback_probe',
    sha256: 'b'.repeat(64), file_reference: 'knowledge/sources/pdfs/rollback_probe.pdf' });
} else if (mode === 'conflict-requirements') {
  dataset.curricula[0].requirements.position_ids = [];
} else if (mode === 'conflict-aliases') {
  dataset.catalogs.find((catalog) => catalog.catalog_type === 'vocabulary').items[0].aliases = [];
} else if (mode === 'conflict-requirement-add') {
  const extra = structuredClone(dataset.catalogs[0].items[0]);
  extra.id = 'fixture_position_extra';
  extra.citation_ids = ['citation_import_extra'];
  dataset.catalogs[0].items.push(extra);
  dataset.provenance[0].citations.push({ ...dataset.provenance[0].citations[0],
    id: 'citation_import_extra', content_id: extra.id });
  dataset.curricula[0].requirements.position_ids.push(extra.id);
} else if (mode === 'conflict-steps') {
  const item = dataset.catalogs.find((catalog) => catalog.catalog_type === 'tul').items[0];
  item.steps.push({ ...item.steps[0], step_number: 2 });
} else if (['apply-text-edit', 'after-text-edit', 'apply-curriculum-edit', 'after-curriculum-edit', 'apply-detail-edit', 'after-detail-edit'].includes(mode)) {
  dataset.catalogs[0].items[0].name = 'Edited synthetic draft';
  dataset.catalogs[0].items[0].description = 'Explicit local revision; test only.';
  if (mode.includes('curriculum') || mode.includes('detail')) dataset.curricula[0].requirements.position_ids = [];
  if (mode.includes('detail')) dataset.catalogs[0].items[0].biomechanics = {
    weight: { front_percent: 47.25, rear_percent: 52.75 }, front_foot: null, rear_foot: { rotation_deg: 25.5 },
  };
} else if (mode !== 'initial') {
  throw new Error('Unknown import test mode');
}
if (mode === 'apply-detail-edit') {
  process.stdout.write(await createDetailEditSql({ id: 'fixture_position', expected_revision: 1, content_type: 'position',
    details: { front_percent: 47.25, rear_percent: 52.75, front_rotation_deg: null, rear_rotation_deg: 25.5 },
    reason: 'Synthetic detail pipeline test.', operator_reference: 'Unverified fixture operator' }));
} else if (mode === 'apply-curriculum-edit') {
  process.stdout.write(await createCurriculumEditSql({ id: 'gup_10', expected_revision: 0,
    requirements: dataset.curricula[0].requirements, reason: 'Synthetic requirements edit.', operator_reference: 'Unverified fixture operator' }));
} else if (mode === 'apply-text-edit') {
  const item = dataset.catalogs[0].items[0];
  process.stdout.write(createDraftEditSql({ id: item.id, expected_revision: 0, name: item.name,
    description: item.description, reason: 'Synthetic pipeline check.', operator_reference: 'Unverified fixture operator' }));
} else {
  process.stdout.write(await createDraftSql(dataset, inventory));
}
