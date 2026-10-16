import { readdir } from 'node:fs/promises';
import path from 'node:path';
import {
  checkLocalSources, createKnowledgeValidator, readJson, repositoryRoot,
} from './lib/knowledge.mjs';
import { discoverCatalogFiles, discoverJsonFiles } from './lib/content-files.mjs';
import { createReviewReport } from './lib/review-report.mjs';

const usage = 'Usage: node validate-knowledge.mjs [--report-json] [--check-local-files] [--require-content] [--knowledge-root PATH] [--inventory PATH] [--provenance PATH ...] [--catalog PATH ...] [--curriculum PATH ...]';

function parseArguments(args) {
  const options = { reportJson: false, local: false, requireContent: false, knowledgeRoot: null, inventory: null, provenance: [], catalog: [], curriculum: [] };
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (arg === '--help') return null;
    if (arg === '--check-local-files') {
      options.local = true;
    } else if (arg === '--report-json') {
      options.reportJson = true;
    } else if (arg === '--require-content') {
      options.requireContent = true;
    } else if (['--knowledge-root', '--inventory', '--provenance', '--catalog', '--curriculum'].includes(arg)) {
      const value = args[++index];
      if (!value || value.startsWith('--')) throw new Error(`Missing path for ${arg}`);
      if (arg === '--knowledge-root') options.knowledgeRoot = path.resolve(value);
      else if (arg === '--inventory') options.inventory = path.resolve(value);
      else options[arg.slice(2)].push(path.resolve(value));
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }
  return options;
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (!options) {
    console.log(usage);
    return;
  }
  const validator = await createKnowledgeValidator();
  const knowledgeRoot = options.knowledgeRoot ?? path.join(repositoryRoot, 'knowledge');
  const inventoryPath = options.inventory ?? path.join(knowledgeRoot, 'sources/inventory.json');
  const inventory = await readJson(inventoryPath);
  const errors = validator.validateInventory(inventory);
  if (!errors.length && options.local) {
    errors.push(...await checkLocalSources(inventory));
  }

  const provenanceDirectory = path.join(knowledgeRoot, 'provenance');
  const discovered = (await readdir(provenanceDirectory, { withFileTypes: true }))
    .filter((entry) => entry.isFile() && entry.name.endsWith('.json'))
    .map((entry) => path.join(provenanceDirectory, entry.name));
  const files = [...new Set([...discovered, ...options.provenance])].sort();
  const citationIds = new Set();
  const citationLocations = new Set();
  const provenance = [];
  let citationCount = 0;
  for (const file of files) {
    const data = await readJson(file);
    provenance.push(data);
    const citationErrors = validator.validateProvenance(data, inventory);
    errors.push(...citationErrors.map((error) => `${path.basename(file)}: ${error}`));
    if (citationErrors.length) continue;
    for (const citation of data.citations) {
      if (citationIds.has(citation.id)) errors.push(`duplicate citation ID across files: ${citation.id}`);
      citationIds.add(citation.id);
      const location = JSON.stringify([
        citation.content_id, citation.source_id, citation.pdf_page, citation.section,
      ]);
      if (citationLocations.has(location)) errors.push(`duplicate citation location across files: ${citation.id}`);
      citationLocations.add(location);
      citationCount++;
    }
  }
  const catalogFiles = await discoverCatalogFiles(path.join(knowledgeRoot, 'catalogs'));
  const catalogPaths = new Map(catalogFiles.map(({ file, type }) => [file, type]));
  for (const file of options.catalog) if (!catalogPaths.has(file)) catalogPaths.set(file, null);
  const catalogs = [];
  for (const [file, expectedType] of catalogPaths) {
    const data = await readJson(file);
    if (expectedType && data?.catalog_type !== expectedType) {
      errors.push(`${file}: catalog_type must match directory type ${expectedType}`);
    }
    catalogs.push(data);
  }
  const curriculumFiles = [...new Set([
    ...await discoverJsonFiles(path.join(knowledgeRoot, 'curricula/gups')),
    ...options.curriculum,
  ])];
  const curricula = await Promise.all(curriculumFiles.map((file) => readJson(file)));
  const checkContent = options.requireContent || catalogs.length > 0 || curricula.length > 0;
  if (checkContent) {
    errors.push(...validator.validateDataset({ catalogs, curricula, provenance }, inventory, {
      requireContent: options.requireContent,
    }));
  }
  if (errors.length) throw new Error(errors.join('\n'));
  if (options.reportJson) {
    const report = createReviewReport({ inventory, catalogs, curricula, provenance }, {
      localPdfIdentitiesChecked: options.local, contentReferencesChecked: Boolean(checkContent),
    });
    console.log(JSON.stringify(report, null, 2));
    return;
  }
  console.log(`PASS: ${inventory.sources.length} sources; ${citationCount} draft citations in ${files.length} files.`);
  console.log(options.local ? 'Local PDF identities checked.' : 'Local PDFs NOT checked.');
  if (!citationCount) console.log('No content citations registered yet; provenance coverage is NOT complete.');
  console.log(`${catalogs.length} catalog files; ${curricula.length} curriculum files.`);
  console.log(checkContent ? 'Content/curriculum references checked against supplied drafts.'
    : 'No content/curriculum data; content existence is NOT validated.');
  console.log('Martial accuracy, curricular completeness, rights and human approval are NOT validated.');
}

try {
  await main();
} catch (error) {
  console.error(`FAIL: ${error.message}`);
  process.exitCode = 1;
}
