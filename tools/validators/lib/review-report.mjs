import { catalogDirectories } from './content.mjs';

// Call only after validation succeeds. This summarizes drafts, not their truth.
export function createReviewReport({ inventory, catalogs, curricula, provenance }, {
  localPdfIdentitiesChecked = false, contentReferencesChecked = false,
} = {}) {
  const items = catalogs.flatMap((catalog) => catalog.items.map((item) => ({
    ...item, catalog_type: catalog.catalog_type,
  })));
  const citations = provenance.flatMap((document) => document.citations);
  return {
    report_version: 1,
    validation: {
      status: 'passed',
      local_pdf_identities_checked: localPdfIdentitiesChecked,
      content_references_checked: contentReferencesChecked,
      not_checked: ['martial_accuracy', 'curricular_completeness', 'human_approval', 'publication_rights'],
    },
    counts: {
      sources: inventory.sources.length,
      catalog_files: catalogs.length,
      content_items: items.length,
      documented_steps: items.filter((item) => item.catalog_type === 'tul')
        .reduce((count, item) => count + item.steps.length, 0),
      citation_files: provenance.length,
      citations: citations.length,
      curricula: curricula.length,
    },
    items_by_type: Object.fromEntries(Object.values(catalogDirectories).map((type) => [
      type, items.filter((item) => item.catalog_type === type).length,
    ])),
    pending_human_review: {
      content_ids: items.filter((item) => item.review_status === 'pending_human_review').map((item) => item.id).sort(),
      citation_ids: citations.filter((citation) => citation.review_status === 'pending_human_review').map((citation) => citation.id).sort(),
      curriculum_ids: curricula.filter((item) => item.review_status === 'pending_human_review').map((item) => item.id).sort(),
    },
    source_usage: inventory.sources.map((source) => ({
      source_id: source.id,
      citation_count: citations.filter((citation) => citation.source_id === source.id).length,
    })),
    incomplete_observations: {
      positions_without_biomechanics: items.filter((item) => item.catalog_type === 'position'
        && item.biomechanics === null).map((item) => item.id).sort(),
      positions_without_both_foot_rotations: items.filter((item) => item.catalog_type === 'position'
        && (!item.biomechanics?.front_foot || !item.biomechanics?.rear_foot)).map((item) => item.id).sort(),
      partial_sequences: items.filter((item) => item.catalog_type === 'tul'
        && !item.sequence_complete).map((item) => item.id).sort(),
      sequences_with_unknown_movement_count: items.filter((item) => item.catalog_type === 'tul'
        && item.movement_count === null).map((item) => item.id).sort(),
      sequences_without_initial_position: items.filter((item) => item.catalog_type === 'tul'
        && item.initial_position_id === null).map((item) => item.id).sort(),
    },
    warnings: [
      ...(!curricula.length ? ['NO_CURRICULUM_REGISTERED'] : []),
      ...(!items.length ? ['NO_CONTENT_REGISTERED'] : []),
      ...(!citations.length ? ['NO_CITATIONS_REGISTERED'] : []),
      'DRAFT_VALIDATION_IS_NOT_PUBLICATION_APPROVAL',
    ],
  };
}
