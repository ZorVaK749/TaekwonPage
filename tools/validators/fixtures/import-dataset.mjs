// Synthetic technical fixtures only; NOT a school syllabus or martial evidence.
export function createImportFixture() {
  const types = ['position', 'theory', 'vocabulary', 'body_tool', 'kick', 'combat', 'tul'];
  const source = {
    id: 'source_import_fixture', file_reference: 'knowledge/sources/pdfs/import_fixture.pdf',
    size_bytes: 10, sha256: 'a'.repeat(64), title: null, author: null, organization: null,
    edition: null, language: null, pdf_pages: 10, metadata_evidence: 'Synthetic fixture.',
    coverage: [], notes: 'Test only.', review_status: 'pending_human_review', redistribution_status: 'unknown',
  };
  const catalogs = types.map((type) => {
    const item = { id: `fixture_${type}`, name: `Synthetic ${type}`,
      description: "Synthetic test: quote ' and backslash \\ and $$, not martial content.",
      citation_ids: [`citation_import_${type}`], review_status: 'pending_human_review' };
    if (type === 'position') item.biomechanics = null;
    if (type === 'vocabulary') Object.assign(item, { translation: 'Synthetic translation', aliases: ["Test ' alias", '$$'] });
    if (type === 'tul') Object.assign(item, {
      movement_count: null, initial_position_id: 'fixture_position', sequence_complete: false,
      sequence_scope: 'Synthetic partial list.',
      steps: [{ step_number: 1, position_id: 'fixture_position', description: 'Synthetic step.', citation_ids: ['citation_import_tul'] }],
    });
    return { format_version: 1, catalog_type: type, items: [item] };
  });
  const curriculum = {
    format_version: 1, id: 'gup_10', gup: 10,
    requirements: Object.fromEntries(types.map((type) => [`${type}_ids`, [`fixture_${type}`]])),
    citation_ids: ['citation_import_curriculum'], review_status: 'pending_human_review',
  };
  const citations = [...types, 'curriculum'].map((type) => ({
    id: `citation_import_${type}`, content_id: type === 'curriculum' ? 'gup_10' : `fixture_${type}`,
    source_id: source.id, source_sha256: source.sha256, pdf_page: 1, printed_page: null,
    section: null, notes: 'Synthetic evidence only.', review_status: 'pending_human_review',
  }));
  return { inventory: { format_version: 1, sources: [source] },
    dataset: { catalogs, curricula: [curriculum], provenance: [{ format_version: 1, citations }] } };
}
