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

const requirementTables = {
  position_ids: ['gup_position', 'position_id'], theory_ids: ['gup_theory', 'theory_id'],
  vocabulary_ids: ['gup_vocabulary', 'vocabulary_id'], body_tool_ids: ['gup_tool', 'tool_id'],
  kick_ids: ['gup_kick', 'kick_id'], tul_ids: ['gup_tul', 'tul_id'], combat_ids: ['gup_combat', 'combat_id'],
};

const tableKeys = {
  source_document: ['id'], content_entry: ['id'], position: ['id'], theory_content: ['id'],
  vocabulary: ['id'], body_tool: ['id'], kick: ['id'], combat_type: ['id'], tul: ['id'], gup: ['id'],
  tul_step: ['tul_id', 'step_number'], content_source: ['id'],
  tul_step_source: ['tul_id', 'step_number', 'citation_id'],
  ...Object.fromEntries(Object.values(requirementTables).map(([table, column]) => [table, ['gup_id', column]])),
};

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
  return createDraftSql({ catalogs, curricula, provenance }, inventory);
}

// Injectable dataset is used by synthetic tests, never to invent a school curriculum.
export async function createDraftSql({ catalogs, curricula, provenance }, inventory) {
  const validator = await createKnowledgeValidator();
  const errors = validator.validateDataset({ catalogs, curricula, provenance }, inventory);
  if (errors.length) throw new Error(errors.join('\n'));
  const lines = [
    '-- LOCAL DRAFTS ONLY. No approval or publication.', 'BEGIN;',
    `LOCK TABLE ${Object.keys(tableKeys).join(', ')} IN SHARE ROW EXCLUSIVE MODE;`,
    `CREATE OR REPLACE FUNCTION pg_temp.assert_draft_import(ok boolean, context text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF NOT ok THEN RAISE EXCEPTION 'draft import conflict: %', context; END IF;
END;
$$;`,
  ];
  const literal = (value) => Array.isArray(value)
    ? `ARRAY[${value.map(sqlValue).join(', ')}]::text[]` : sqlValue(value);
  const assert = (condition, context) => lines.push(`SELECT pg_temp.assert_draft_import((${condition}), ${sqlValue(context)});`);
  const insert = (table, row) => {
    const keys = tableKeys[table];
    if (!keys) throw new Error('Unsupported import table');
    lines.push(`INSERT INTO ${table} (${Object.keys(row).join(', ')}) VALUES (${Object.values(row).map(literal).join(', ')}) ON CONFLICT (${keys.join(', ')}) DO NOTHING;`);
    // Identical reload is a no-op. A changed value must never be silently ignored.
    const equal = Object.entries(row).map(([column, value]) => `${column} IS NOT DISTINCT FROM ${literal(value)}`).join(' AND ');
    assert(`EXISTS (SELECT 1 FROM ${table} WHERE ${equal})`, table);
  };
  const count = (table, column, id, expected) => assert(
    `(SELECT count(*) FROM ${table} WHERE ${column} = ${sqlValue(id)}) = ${expected}`, `${table} membership`);
  const existingMembership = (parent, id, table, column, expected) => assert(
    `NOT EXISTS (SELECT 1 FROM ${parent} WHERE id = ${sqlValue(id)}) OR (SELECT count(*) FROM ${table} WHERE ${column} = ${sqlValue(id)}) = ${expected}`,
    `${table} existing membership`);
  const citationCount = (id) => provenance.flatMap((document) => document.citations)
    .filter((citation) => citation.content_id === id).length;
  for (const source of inventory.sources) {
    const { id, sha256, size_bytes, pdf_pages, title, organization, author, edition, language,
      file_reference, metadata_evidence, notes, review_status, redistribution_status } = source;
    insert('source_document', { id, sha256, size_bytes, pdf_pages, title, organization, author,
      edition, language, file_reference, metadata_evidence, notes, review_status, redistribution_status });
  }
  for (const catalog of catalogs) for (const item of catalog.items) {
    existingMembership('content_entry', item.id, 'content_source', 'content_id', citationCount(item.id));
    insert('content_entry', { id: item.id, content_type: catalog.catalog_type, name: item.name,
      description: item.description, review_status: item.review_status });
  }
  for (const curriculum of curricula) {
    existingMembership('content_entry', curriculum.id, 'content_source', 'content_id', citationCount(curriculum.id));
    // Technical labels only: the Gup contract has no martial title/description fields.
    insert('content_entry', { id: curriculum.id, content_type: 'gup', name: curriculum.id,
      description: 'Currículo de trabajo; requisitos referenciados por ID.', review_status: curriculum.review_status });
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
        insert('vocabulary', { ...row, translation: item.translation, aliases: item.aliases });
        break;
      case 'tul':
        existingMembership('tul', item.id, 'tul_step', 'tul_id', item.steps.length);
        for (const step of item.steps) assert(
          `NOT EXISTS (SELECT 1 FROM tul_step WHERE tul_id = ${sqlValue(item.id)} AND step_number = ${step.step_number}) OR (SELECT count(*) FROM tul_step_source WHERE tul_id = ${sqlValue(item.id)} AND step_number = ${step.step_number}) = ${step.citation_ids.length}`,
          'tul_step_source existing membership');
        insert('tul', { ...row, movement_count: item.movement_count, initial_position_id: item.initial_position_id,
          sequence_complete: item.sequence_complete, sequence_scope: item.sequence_scope });
        for (const step of item.steps) insert('tul_step', { tul_id: item.id, step_number: step.step_number,
          position_id: step.position_id, description: step.description });
        break;
      default:
        insert({ theory: 'theory_content', body_tool: 'body_tool', kick: 'kick', combat: 'combat_type' }[catalog.catalog_type], row);
    }
  }
  for (const curriculum of curricula) {
    for (const [field, [table]] of Object.entries(requirementTables)) {
      existingMembership('gup', curriculum.id, table, 'gup_id', curriculum.requirements[field].length);
    }
    insert('gup', { id: curriculum.id, gup: curriculum.gup });
    for (const [field, [table, column]] of Object.entries(requirementTables)) {
      for (const id of curriculum.requirements[field]) insert(table, { gup_id: curriculum.id, [column]: id });
      count(table, 'gup_id', curriculum.id, curriculum.requirements[field].length);
    }
  }
  for (const document of provenance) for (const citation of document.citations) insert('content_source', citation);
  for (const catalog of catalogs.filter((c) => c.catalog_type === 'tul')) for (const item of catalog.items) {
    count('tul_step', 'tul_id', item.id, item.steps.length);
    for (const step of item.steps) for (const citation of step.citation_ids) {
      insert('tul_step_source', { tul_id: item.id, step_number: step.step_number, citation_id: citation });
    }
    // Also detect removed per-step citation links, including on unchanged steps.
    for (const step of item.steps) assert(
      `(SELECT count(*) FROM tul_step_source WHERE tul_id = ${sqlValue(item.id)} AND step_number = ${step.step_number}) = ${step.citation_ids.length}`,
      'tul_step_source membership');
  }
  for (const item of [...catalogs.flatMap((catalog) => catalog.items), ...curricula]) {
    count('content_source', 'content_id', item.id, citationCount(item.id));
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
