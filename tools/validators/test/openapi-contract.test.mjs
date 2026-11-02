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

// Every controller route in the code, as the contract spells it: "METHOD /base/path".
const controllerRoutes = new Map();
for (const file of collectJavaFiles(sourceRoot).filter((name) => name.endsWith('Controller.java'))) {
  const source = readFileSync(file, 'utf8');
  const controller = path.basename(file);
  const base = source.match(/@RequestMapping\("([^"]+)"\)/)?.[1];
  assert.ok(base, `${controller} must declare a class-level request mapping`);
  for (const mapping of source.matchAll(/@GetMapping\("([^"]+)"\)/g)) {
    controllerRoutes.set(`GET ${base}${mapping[1]}`, controller);
  }
  for (const mapping of source.matchAll(/@PostMapping\("([^"]+)"\)/g)) {
    controllerRoutes.set(`POST ${base}${mapping[1]}`, controller);
  }
  // Only the credential exchange may write; everything else stays read-only.
  const writes = source.match(/@(Put|Patch|Delete)Mapping/g) ?? [];
  assert.deepEqual(writes, [], `${controller} must stay read-only`);
  if (controller !== 'AuthController.java') {
    assert.ok(!/@PostMapping/.test(source), `${controller} must not add POST routes`);
  }
  // Controllers that parse a path parameter must reject malformed ids with 400.
  if (/@PathVariable/.test(source)) {
    assert.match(source, /ResponseStatusException\(HttpStatus\.BAD_REQUEST\)/,
      `${controller} must reject malformed ids before querying`);
  }
}

const readRoutes = (route) => !route.startsWith('/api/v1/auth/') && route !== '/api/v1/me';

test('the contract documents exactly the implemented routes', () => {
  assert.match(contract.openapi, /^3\.1\./);
  assert.equal(contract.info.title, 'TaeKwonPage API');
  assert.ok(contract.info.description.includes('403'));
  const documented = new Set();
  for (const [route, operations] of Object.entries(contract.paths)) {
    for (const method of Object.keys(operations)) {
      if (method === 'parameters') continue;
      documented.add(`${method.toUpperCase()} ${route}`);
    }
  }
  assert.deepEqual([...documented].sort(), [...controllerRoutes.keys()].sort());
  for (const route of documented) assert.ok(controllerRoutes.has(route), `${route} has no controller`);
});

test('no server, schema or operation advertises a public host or a global auth requirement', () => {
  for (const server of contract.servers) {
    assert.match(server.url, /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/);
  }
  // C1 is implemented, so the scheme exists; but no global requirement may be
  // declared: content routes are still deny-all and cannot inherit bearer auth.
  assert.equal(contract.security, undefined, 'content routes stay deny-all without a global security requirement');
  const scheme = contract.components.securitySchemes?.bearerAuth;
  assert.ok(scheme, 'the local bearer scheme (C1) must be documented');
  assert.equal(scheme.type, 'http');
  assert.equal(scheme.scheme, 'bearer');
  assert.equal(scheme.bearerFormat, 'JWT');
  for (const [route, operations] of Object.entries(contract.paths)) {
    const methods = Object.keys(operations).filter((key) => key !== 'parameters');
    if (readRoutes(route)) {
      assert.deepEqual(methods, ['get'], `${route} must document GET only`);
      const operation = operations.get;
      assert.ok(operation.operationId, `${route} needs a stable operationId`);
      for (const status of ['200', '400', '403', '404']) {
        assert.ok(operation.responses[status], `${route} must document ${status}`);
      }
      assert.match(operation.responses['403'].description, /deny-all/);
      assert.match(operation.responses['404'].description, /no se rellena/);
      assert.equal(operation.parameters.length, 1);
      // Path parameters are restricted to these two: the canonical id or the raw gup number.
      assert.ok([
        '#/components/parameters/CanonicalId',
        '#/components/parameters/GupNumber',
      ].includes(operation.parameters[0].$ref), `${route} declares an unexpected path parameter`);
      assert.equal(operation.security, undefined, `${route} must not require a token while deny-all applies`);
    }
  }
  const operationIds = [];
  for (const operations of Object.values(contract.paths)) {
    for (const [method, operation] of Object.entries(operations)) {
      if (method === 'parameters') continue;
      operationIds.push(operation.operationId);
    }
  }
  assert.equal(new Set(operationIds).size, operationIds.length, 'operationIds must be unique');
});

test('identity routes document the local token exchange without inventing a flow', () => {
  const login = contract.paths['/api/v1/auth/login']?.post;
  assert.ok(login, 'POST /api/v1/auth/login must be documented');
  assert.deepEqual(login.security, [], 'login is public: no token is required to obtain one');
  assert.equal(login.requestBody.required, true);
  assert.equal(login.requestBody.content['application/json'].schema.$ref, '#/components/schemas/LoginRequest');
  assert.deepEqual(Object.keys(login.responses).sort(), ['200', '400', '401']);
  assert.equal(login.responses['200'].content['application/json'].schema.$ref, '#/components/schemas/TokenResponse');
  assert.match(login.responses['401'].description, /no enumerar cuentas/);
  assert.ok(!login.responses['403'], 'login is permitAll and must not document 403');
  assert.ok(!('parameters' in login), 'login takes a body, not path parameters');

  const me = contract.paths['/api/v1/me']?.get;
  assert.ok(me, 'GET /api/v1/me must be documented');
  assert.deepEqual(me.security, [{ bearerAuth: [] }], 'me requires the local bearer token');
  assert.deepEqual(Object.keys(me.responses).sort(), ['200', '401']);
  assert.equal(me.responses['200'].content['application/json'].schema.$ref, '#/components/schemas/MeResponse');
  assert.ok(!('403' in me.responses), 'identity read answers 401, never the content 403');
  assert.ok(!('parameters' in me), 'me takes no parameters');

  const loginRequest = contract.components.schemas.LoginRequest;
  assert.equal(loginRequest.additionalProperties, false);
  assert.deepEqual(loginRequest.required, ['username', 'password']);
  assert.equal(loginRequest.properties.username.pattern, '^[A-Za-z0-9._-]+$');
  const token = contract.components.schemas.TokenResponse;
  assert.deepEqual(token.required, ['access_token', 'token_type', 'expires_in']);
  assert.deepEqual(token.properties.token_type.enum, ['Bearer']);
  assert.ok(token.properties.expires_in.minimum >= 1);
  const meResponse = contract.components.schemas.MeResponse;
  assert.deepEqual(meResponse.required, ['id', 'username', 'roles']);
  assert.equal(meResponse.properties.id.$ref, '#/components/schemas/CanonicalId');
  assert.equal(meResponse.properties.roles.items.pattern, '^ROLE_[A-Z_]+$');
  // The identity schemas must not leak grade, email or content fields.
  for (const name of ['gup', 'grade', 'email', 'passwordHash', 'password_hash']) {
    assert.ok(!(name in meResponse.properties), `me must not expose ${name}`);
  }
});

test('canonical id and provenance limits are part of the published contract', () => {
  const parameter = contract.components.parameters.CanonicalId;
  assert.equal(parameter.in, 'path');
  assert.equal(parameter.required, true);
  assert.equal(parameter.schema.pattern, '^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
  const gupNumber = contract.components.parameters.GupNumber;
  assert.equal(gupNumber.in, 'path');
  assert.equal(gupNumber.required, true);
  assert.equal(gupNumber.schema.type, 'integer');
  assert.equal(gupNumber.schema.minimum, 1);
  assert.equal(gupNumber.schema.maximum, 10);
  const citation = contract.components.schemas.Citation;
  assert.equal(citation.properties.sourceSha256.pattern, '^[a-f0-9]{64}$');
  assert.equal(citation.properties.reviewStatus.$ref, '#/components/schemas/ReviewStatus');
  assert.equal(citation.properties.sourceReviewStatus.$ref, '#/components/schemas/ReviewStatus');
  assert.deepEqual(citation.properties.redistributionStatus.enum, ['unknown']);
  assert.deepEqual(contract.components.schemas.ReviewStatus.enum, ['pending_human_review']);
  assert.ok('sequenceComplete' in contract.components.schemas.Tul.properties);
  assert.ok('movementCount' in contract.components.schemas.Tul.properties);
  assert.ok('translation' in contract.components.schemas.Vocabulary.properties);
  // The curriculum read exposes exactly the seven observed groups and nothing else.
  const gup = contract.components.schemas.Gup;
  assert.ok('requirements' in gup.properties);
  assert.equal(gup.properties.gup.minimum, 1);
  assert.equal(gup.properties.gup.maximum, 10);
  const groups = contract.components.schemas.GupRequirements;
  assert.deepEqual(Object.keys(groups.properties).sort(), [
    'bodyToolIds', 'combatIds', 'kickIds', 'positionIds', 'theoryIds', 'tulIds', 'vocabularyIds',
  ]);
  assert.equal(Object.keys(groups.properties).length, 7);
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
  // Exactly two public entrances: health and the credential exchange.
  assert.equal(securitySource.match(/permitAll\(\)/g).length, 3, 'health/login plus internal ERROR dispatch only');
  assert.match(securitySource, /dispatcherTypeMatchers\(DispatcherType\.ERROR\)\.permitAll\(\)/);
  assert.match(securitySource, /requestMatchers\(HttpMethod\.GET, "\/actuator\/health"\)\.permitAll\(\)/);
  assert.match(securitySource, /requestMatchers\(HttpMethod\.POST, "\/api\/v1\/auth\/login"\)\.permitAll\(\)/);
  assert.match(securitySource, /requestMatchers\("\/api\/v1\/me"\)\.authenticated\(\)/);
  // Bearer-only, stateless API: no session, no CSRF surface, no form or basic fallback.
  assert.match(securitySource, /new JwtAuthenticationFilter\(jwt\)/);
  assert.match(securitySource, /\.csrf\(AbstractHttpConfigurer::disable\)/);
  assert.match(securitySource, /SessionCreationPolicy\.STATELESS/);
  assert.ok(!/formLogin\((?!AbstractHttpConfigurer::disable)/.test(securitySource), 'form login stays disabled');
  assert.ok(!/httpBasic\((?!AbstractHttpConfigurer::disable)/.test(securitySource), 'basic auth stays disabled');
  // Denied requests keep the historical 403 outside the identity read.
  assert.match(securitySource, /SC_FORBIDDEN/);
  assert.match(securitySource, /SC_UNAUTHORIZED/);
});
