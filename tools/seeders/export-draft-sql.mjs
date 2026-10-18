// Explicit local draft import, never a publication seed. No database dependency.
import path from 'node:path';
import { createKnowledgeValidator, readJson, repositoryRoot } from '../validators/lib/knowledge.mjs';
import { discoverCatalogFiles, discoverJsonFiles } from '../validators/lib/content-files.mjs';

export function sqlValue(value) {
  if (value === null || value === undefined) return 'NULL';
  if (typeof value === 'boolean') return value ? 'TRUE' : 'FALSE';
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  if (typeof value !== 'string' || value.includes('\0')) throw new Error('Unsupported SQL value');
  // E literals make escaping independent of standard_conforming_strings.
  return `E'${value.replaceAll('\\', '\\\\').replaceAll("'", "''")}'`;
}

export async function exportDraftSql() {
  const root = path.join(repositoryRoot, 'knowledge');
  const inventory = await readJson(path.join(root, 'sources/inventory.json'));
  const catalogFiles = await discoverCatalogFiles(path.join(root, 'catalogs'));
  const catalogs = await Promise.all(catalogFiles.map(async ({ file, type }) => {
    const catalog = await readJson(file);
    if (catalog.catalog_type !== type) throw new Error('Catalog directory/type mismatch');
    return catalog;
  }));
  const provenance = await Promise.all((await discoverJsonFiles(path.join(root, 'provenance'))).map(readJson));
  const curricula = await Promise.all((await discoverJsonFiles(path.join(root, 'curricula/gups'))).map(readJson));
  const validator = await createKnowledgeValidator();
  const errors = validator.validateDataset({ catalogs, curricula, provenance }, inventory);
  if (errors.length) throw new Error(errors.join('\n'));
  // Until a real curriculum and its mapping are reviewed, do not silently skip it.
  if (curricula.length) throw new Error('Curriculum import mapping is not implemented; refusing partial import');
  const lines = ['-- LOCAL DRAFTS ONLY. No approval or publication.', 'BEGIN;'];
  const insert = (table, row) => lines.push(`INSERT INTO ${table} (${Object.keys(row).join(', ')}) VALUES (${Object.values(row).map(sqlValue).join(', ')});`);
  for (const source of inventory.sources) {
    const { id, sha256, size_bytes, pdf_pages, title, organization, author, edition, language,
      file_reference, metadata_evidence, notes, review_status, redistribution_status } = source;
    insert('source_document', { id, sha256, size_bytes, pdf_pages, title, organization, author,
      edition, language, file_reference, metadata_evidence, notes, review_status, redistribution_status });
  }
  for (const catalog of catalogs) for (const item of catalog.items) {
    insert('content_entry', { id: item.id, content_type: catalog.catalog_type, name: item.name,
      description: item.description, review_status: item.review_status });
  }
  // Positions must precede exercises referencing them.
  const ordered = [...catalogs].sort((a, b) => Number(b.catalog_type === 'position') - Number(a.catalog_type === 'position'));
  for (const catalog of ordered) for (const item of catalog.items) {
    const row = { id: item.id };
    switch (catalog.catalog_type) {
      case 'position': {
        const b = item.biomechanics;
        insert('position', { ...row, front_percent: b?.weight?.front_percent,
          rear_percent: b?.weight?.rear_percent, front_rotation_deg: b?.front_foot?.rotation_deg,
          rear_rotation_deg: b?.rear_foot?.rotation_deg });
        break;
      }
      case 'vocabulary':
        insert('vocabulary', { ...row, translation: item.translation });
        // Build arrays from separately quoted elements, not PostgreSQL array literals.
        lines.push(`UPDATE vocabulary SET aliases = ARRAY[${item.aliases.map(sqlValue).join(', ')}]::text[] WHERE id = ${sqlValue(item.id)};`);
        break;
      case 'tul':
        insert('tul', { ...row, movement_count: item.movement_count, initial_position_id: item.initial_position_id,
          sequence_complete: item.sequence_complete, sequence_scope: item.sequence_scope });
        for (const step of item.steps) insert('tul_step', { tul_id: item.id, step_number: step.step_number,
          position_id: step.position_id, description: step.description });
        break;
      default:
        insert({ theory: 'theory_content', body_tool: 'body_tool', kick: 'kick', combat: 'combat_type' }[catalog.catalog_type], row);
    }
  }
  for (const document of provenance) for (const citation of document.citations) insert('content_source', citation);
  for (const catalog of catalogs.filter((c) => c.catalog_type === 'tul')) for (const item of catalog.items) {
    for (const step of item.steps) for (const citation of step.citation_ids) {
      insert('tul_step_source', { tul_id: item.id, step_number: step.step_number, citation_id: citation });
    }
  }
  lines.push('COMMIT;');
  return lines.join('\n') + '\n';
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.join(repositoryRoot, 'tools/seeders/export-draft-sql.mjs')) {
  try {
    if (process.argv.slice(2).join(' ') !== '--local-drafts') throw new Error('Usage: node tools/seeders/export-draft-sql.mjs --local-drafts');
    process.stdout.write(await exportDraftSql());
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
