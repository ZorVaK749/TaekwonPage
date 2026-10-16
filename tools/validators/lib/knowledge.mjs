import Ajv2020 from 'ajv/dist/2020.js';
import { createHash } from 'node:crypto';
import { open, readdir, readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createContentChecks } from './content.mjs';

export const repositoryRoot = fileURLToPath(new URL('../../../', import.meta.url));
const schemaDirectory = new URL('../../../knowledge/schemas/', import.meta.url);
const schemaNames = [
  'common', 'source', 'source-inventory', 'content-source', 'provenance',
  'content-entry', 'position', 'theory', 'tul', 'vocabulary', 'body-tool', 'kick', 'combat', 'catalog', 'gup',
];

export async function readJson(file) {
  // Fatal UTF-8 decoding: malformed source text must not be silently replaced.
  const bytes = await readFile(file);
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}

export async function createKnowledgeValidator() {
  const ajv = new Ajv2020({ strict: true, allErrors: true, ownProperties: true });
  for (const name of schemaNames) {
    ajv.addSchema(await readJson(new URL(`${name}.schema.json`, schemaDirectory)));
  }
  // Eager compilation also detects broken local refs without input data or PDFs.
  const validateInventorySchema = ajv.getSchema('urn:taekwonpage:schema:source_inventory:1');
  const validateProvenanceSchema = ajv.getSchema('urn:taekwonpage:schema:provenance:1');

  function schemaErrors(validate, data) {
    if (validate(data)) return [];
    return validate.errors.map((error) => `${error.instancePath || '/'}: ${error.message}`);
  }

  function validateInventory(inventory) {
    const errors = schemaErrors(validateInventorySchema, inventory);
    if (errors.length) return errors;
    const seen = { id: new Set(), file_reference: new Set(), sha256: new Set() };
    for (const source of inventory.sources) {
      for (const field of Object.keys(seen)) {
        // References must also be unambiguous on Windows filesystems.
        const value = field === 'file_reference'
          ? source[field].normalize('NFC').toLowerCase() : source[field];
        if (seen[field].has(value)) errors.push(`${source.id}: duplicate ${field}`);
        seen[field].add(value);
      }
      const knownMetadata = ['title', 'organization', 'author', 'edition', 'language', 'pdf_pages']
        .some((field) => source[field] !== null);
      if (knownMetadata && source.metadata_evidence === null) {
        errors.push(`${source.id}: known metadata requires evidence`);
      }
      for (const coverage of source.coverage) {
        if (source.pdf_pages === null || coverage.pdf_page_start > coverage.pdf_page_end
          || coverage.pdf_page_end > source.pdf_pages) {
          errors.push(`${source.id}: coverage pages outside PDF bounds`);
        }
      }
    }
    return errors;
  }

  function validateProvenance(provenance, inventory) {
    const errors = validateInventory(inventory);
    if (errors.length) return errors.map((error) => `inventory: ${error}`);
    errors.push(...schemaErrors(validateProvenanceSchema, provenance));
    if (errors.length) return errors;
    const sources = new Map(inventory.sources.map((source) => [source.id, source]));
    const ids = new Set();
    const locations = new Set();
    for (const citation of provenance.citations) {
      if (ids.has(citation.id)) errors.push(`${citation.id}: duplicate citation ID`);
      ids.add(citation.id);
      const location = JSON.stringify([
        citation.content_id, citation.source_id, citation.pdf_page, citation.section,
      ]);
      if (locations.has(location)) errors.push(`${citation.id}: duplicate content/source location`);
      locations.add(location);
      const source = sources.get(citation.source_id);
      if (!source) {
        errors.push(`${citation.id}: unknown source_id ${citation.source_id}`);
        continue;
      }
      if (citation.source_sha256 !== source.sha256) {
        errors.push(`${citation.id}: source SHA-256 differs from registered copy`);
      }
      if (citation.pdf_page !== null && (source.pdf_pages === null
        || citation.pdf_page > source.pdf_pages)) {
        errors.push(`${citation.id}: PDF page cannot be verified against inventory bounds`);
      }
    }
    return errors;
  }

  const contentChecks = createContentChecks({
    schemaErrors, validateInventory, validateProvenance,
    catalogSchema: ajv.getSchema('urn:taekwonpage:schema:catalog:1'),
    gupSchema: ajv.getSchema('urn:taekwonpage:schema:gup:1'),
  });
  return { validateInventory, validateProvenance, ...contentChecks };
}

export async function checkLocalSources(inventory, root = repositoryRoot) {
  const errors = [];
  const pdfDirectory = path.join(root, 'knowledge/sources/pdfs');
  let actualDirectory;
  try {
    actualDirectory = await realpath(pdfDirectory);
  } catch (error) {
    return [`local PDFs unavailable: ${error.code ?? error.message}`];
  }
  const references = new Set(inventory.sources.map((source) => source.file_reference));
  for (const source of inventory.sources) {
    const filename = path.join(root, source.file_reference);
    let handle;
    try {
      const actualFile = await realpath(filename);
      if (path.dirname(actualFile) !== actualDirectory) {
        errors.push(`${source.id}: PDF resolves outside the local source directory`);
        continue;
      }
      handle = await open(actualFile, 'r');
      const stat = await handle.stat();
      if (!stat.isFile() || stat.size !== source.size_bytes) {
        errors.push(`${source.id}: local file type/size mismatch`);
        continue;
      }
      const header = Buffer.alloc(5);
      await handle.read(header, 0, 5, 0);
      if (header.toString('ascii') !== '%PDF-') errors.push(`${source.id}: invalid PDF header`);
      // Stream hashing avoids loading the 42 MB source into memory at once.
      const hash = createHash('sha256');
      for await (const chunk of handle.createReadStream({ start: 0, autoClose: false })) {
        hash.update(chunk);
      }
      if (hash.digest('hex') !== source.sha256) errors.push(`${source.id}: local SHA-256 mismatch`);
    } catch (error) {
      errors.push(`${source.id}: local PDF unavailable (${error.code ?? error.message})`);
    } finally {
      await handle?.close();
    }
  }

  async function findUnregistered(directory, prefix) {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const reference = `${prefix}/${entry.name}`;
      if (entry.isDirectory()) {
        await findUnregistered(path.join(directory, entry.name), reference);
      } else if (/\.pdf$/i.test(entry.name) && !references.has(reference)) {
        errors.push(`unregistered local PDF: ${reference}`);
      } else if (entry.isSymbolicLink()) {
        errors.push(`symbolic link not supported in sources: ${reference}`);
      }
    }
  }
  await findUnregistered(pdfDirectory, 'knowledge/sources/pdfs');
  return errors;
}
