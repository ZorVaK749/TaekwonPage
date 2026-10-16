import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { createReviewReport } from '../lib/review-report.mjs';

const cli = fileURLToPath(new URL('../validate-knowledge.mjs', import.meta.url));

test('empty report never presents missing content as a completed curriculum', () => {
  const report = createReviewReport({ inventory: { sources: [] }, catalogs: [], curricula: [], provenance: [] });
  assert.equal(report.counts.content_items, 0);
  assert.equal(report.validation.local_pdf_identities_checked, false);
  assert.equal(report.validation.content_references_checked, false);
  assert.ok(report.warnings.includes('NO_CURRICULUM_REGISTERED'));
  assert.ok(report.warnings.includes('NO_CONTENT_REGISTERED'));
  assert.ok(report.warnings.includes('NO_CITATIONS_REGISTERED'));
  assert.ok(report.validation.not_checked.includes('human_approval'));
});

test('JSON CLI report is parseable, counts real drafts and preserves pending review', () => {
  const result = spawnSync(process.execPath, [cli, '--report-json'], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const report = JSON.parse(result.stdout);
  assert.equal(report.report_version, 1);
  assert.equal(report.validation.content_references_checked, true);
  assert.equal(report.validation.local_pdf_identities_checked, false);
  assert.equal(report.counts.content_items, report.pending_human_review.content_ids.length);
  assert.equal(report.counts.citations, report.pending_human_review.citation_ids.length);
  assert.equal(Object.values(report.items_by_type).reduce((sum, value) => sum + value, 0), report.counts.content_items);
  assert.equal(report.source_usage.reduce((sum, source) => sum + source.citation_count, 0), report.counts.citations);
  assert.ok(report.incomplete_observations.positions_without_biomechanics.includes('charyot_sogi'));
  assert.ok(report.incomplete_observations.positions_without_both_foot_rotations.includes('niunja_sogi'));
  assert.ok(report.warnings.includes('DRAFT_VALIDATION_IS_NOT_PUBLICATION_APPROVAL'));
  assert.ok(!result.stdout.includes('description'), 'Summary should not duplicate source-derived content.');
});

test('JSON report with strict presence gate still fails until curriculum exists', () => {
  const result = spawnSync(process.execPath, [cli, '--report-json', '--require-content'], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.match(result.stderr, /foundation incomplete/);
});
