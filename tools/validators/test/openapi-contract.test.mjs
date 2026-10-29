import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { readJson, repositoryRoot } from '../lib/knowledge.mjs';

const contract = await readJson(path.join(repositoryRoot, 'docs', 'openapi', 'taekwonpage-v1.json'));
const sourceRoot = path.join(repositoryRoot, 'backend', 'taekwonpage-api', 'src', 'main', 'java');
const securitySource = readFileSync(
  path.join(sourceRoot, 'tech', 'zvk', 'taekwonpage', 'shared', 'security', 'SecurityConfiguration.java'),
  'utf8');

function collectJavaFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...collectJavaFiles(full));
    else if (entry.name.endsWith('.java')) files.push(full);
  }
  return files;
}

// Every controller route in the code, as the contract spells it: base + method path.
const controllerRoutes = new Map();
for (const file of collectJavaFiles(sourceRoot).filter((name) => name.endsWith('Controller.java'))) {
  const source = readFileSync(file, 'utf8');
  const base = source.match(/@RequestMapping\("([^"]+)"\)/)?.[1];
  assert.ok(base, `${path.basename(file)} must declare a class-level request mapping`);
  for (const mapping of source.matchAll(/@GetMapping\("([^"]+)"\)/g)) {
    controllerRoutes.set(`${base}${mapping[1]}`, path.basename(file));
  }
  assert.ok(!/@(Post|Put|Patch|Delete)Mapping/.test(source),
    `${path.basename(file)} must stay read-only until Fase 3`);
  assert.match(source, /ResponseStatusException\(HttpStatus\.BAD_REQUEST\)/,
    `${path.basename(file)} must reject malformed ids before querying`);
}

test('the contract documents exactly the implemented read routes', () => {
  assert.match(contract.openapi, /^3\.1\./);
  assert.equal(contract.info.title, 'TaeKwonPage API');
  assert.ok(contract.info.description.includes('403'));
  const documented = new Set(Object.keys(contract.paths).filter((route) => route.startsWith('/api/v1')));
  assert.deepEqual([...documented].sort(), [...controllerRoutes.keys()].sort());
  for (const route of documented) assert.ok(controllerRoutes.has(route), `${route} has no controller`);
});

test('no server, schema or operation advertises an identity or a public host', () => {
  for (const server of contract.servers) {
    assert.match(server.url, /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/);
  }
  assert.equal(contract.components.securitySchemes, undefined, 'identity (Fase 3) is still undecided');
  assert.equal(contract.security, undefined, 'no auth scheme may be invented before JWT/OIDC is chosen');
  for (const [route, operations] of Object.entries(contract.paths)) {
    assert.deepEqual(Object.keys(operations).filter((key) => key !== 'parameters'),
      ['get'], `${route} must document GET only`);
    const operation = operations.get;
    assert.ok(operation.operationId, `${route} needs a stable operationId`);
    for (const status of ['200', '400', '403', '404']) {
      assert.ok(operation.responses[status], `${route} must document ${status}`);
    }
    assert.match(operation.responses['403'].description, /deny-all/);
    assert.match(operation.responses['404'].description, /no se rellena/);
    assert.equal(operation.parameters.length, 1);
    assert.equal(operation.parameters[0].$ref, '#/components/parameters/CanonicalId');
  }
  assert.equal(new Set(Object.values(contract.paths).map((route) => route.get.operationId)).size,
    Object.keys(contract.paths).length, 'operationIds must be unique');
});

test('canonical id and provenance limits are part of the published contract', () => {
  const parameter = contract.components.parameters.CanonicalId;
  assert.equal(parameter.in, 'path');
  assert.equal(parameter.required, true);
  assert.equal(parameter.schema.pattern, '^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
  const citation = contract.components.schemas.Citation;
  assert.equal(citation.properties.sourceSha256.pattern, '^[a-f0-9]{64}$');
  assert.equal(citation.properties.reviewStatus.$ref, '#/components/schemas/ReviewStatus');
  assert.equal(citation.properties.sourceReviewStatus.$ref, '#/components/schemas/ReviewStatus');
  assert.deepEqual(citation.properties.redistributionStatus.enum, ['unknown']);
  assert.deepEqual(contract.components.schemas.ReviewStatus.enum, ['pending_human_review']);
  assert.ok('sequenceComplete' in contract.components.schemas.Tul.properties);
  assert.ok('movementCount' in contract.components.schemas.Tul.properties);
  assert.ok('translation' in contract.components.schemas.Vocabulary.properties);
});

test('schemas expose no local file paths, internal notes or unreviewed states', () => {
  const forbidden = /file.?reference|file_?path|pdf_?path|internal.?notes|^notes$/i;
  const walk = (node, trail) => {
    if (Array.isArray(node)) return node.forEach((item) => walk(item, trail));
    if (!node || typeof node !== 'object') return;
    for (const [key, value] of Object.entries(node)) {
      if (key === 'properties') {
        for (const property of Object.keys(value)) {
          assert.ok(!forbidden.test(property), `schema must not expose ${trail}.${property}`);
        }
      }
      walk(value, `${trail}.${key}`);
    }
  };
  walk(contract.components.schemas, 'schemas');
  // Every $ref resolves inside the document.
  const refs = [];
  const collectRefs = (node) => {
    if (Array.isArray(node)) return node.forEach(collectRefs);
    if (!node || typeof node !== 'object') return;
    for (const [key, value] of Object.entries(node)) {
      if (key === '$ref') refs.push(value);
      else collectRefs(value);
    }
  };
  collectRefs(contract);
  for (const ref of refs) {
    const target = ref.replace(/^#\//, '').split('/').reduce((node, key) => node?.[key], contract);
    assert.ok(target, `unresolved reference ${ref}`);
  }
});

test('the deny-all posture documented by the contract is still the one in code', () => {
  assert.match(securitySource, /\.anyRequest\(\)\.denyAll\(\)\)/);
  assert.equal(securitySource.match(/permitAll\(\)/g).length, 1, 'only health may stay public');
  assert.match(securitySource, /requestMatchers\(HttpMethod\.GET, "\/actuator\/health"\)/);
});
