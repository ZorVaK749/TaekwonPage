// Called only by database tests. Never adds files to knowledge/curricula.
import { createImportFixture } from './fixtures/import-dataset.mjs';
import { createDraftSql } from '../seeders/export-draft-sql.mjs';

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
} else if (mode !== 'initial') {
  throw new Error('Unknown import test mode');
}
process.stdout.write(await createDraftSql(dataset, inventory));
