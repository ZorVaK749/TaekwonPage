import { readdir } from 'node:fs/promises';
import path from 'node:path';
import { catalogDirectories } from './content.mjs';

export async function discoverJsonFiles(directory) {
  const files = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symbolic links are not supported in knowledge: ${file}`);
    if (entry.isDirectory()) files.push(...await discoverJsonFiles(file));
    else if (entry.isFile() && /\.json$/i.test(entry.name)) files.push(file);
  }
  return files.sort();
}

export async function discoverCatalogFiles(directory) {
  return (await discoverJsonFiles(directory)).map((file) => {
    const category = path.relative(directory, file).split(path.sep)[0];
    const type = catalogDirectories[category];
    if (!Object.hasOwn(catalogDirectories, category)) throw new Error(`Unknown catalog directory: ${file}`);
    return { file, type };
  });
}
