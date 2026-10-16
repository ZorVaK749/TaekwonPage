export const catalogDirectories = {
  posiciones: 'position', teoria: 'theory', tuls: 'tul', vocabulario: 'vocabulary',
  herramientas: 'body_tool', patadas: 'kick', combate: 'combat',
};

export function createContentChecks({ schemaErrors, catalogSchema, gupSchema, validateInventory, validateProvenance }) {
  const validateCatalog = (data) => schemaErrors(catalogSchema, data);
  const validateCurriculum = (data) => schemaErrors(gupSchema, data);

  function validateDataset(dataset, inventory, { requireContent = false } = {}) {
    const errors = validateInventory(inventory);
    if (errors.length) return errors;
    if (!dataset || !['catalogs', 'curricula', 'provenance'].every((key) => Array.isArray(dataset[key]))) {
      return ['dataset must contain catalogs, curricula and provenance arrays'];
    }
    for (const [index, catalog] of dataset.catalogs.entries()) {
      errors.push(...validateCatalog(catalog).map((error) => `catalog ${index}: ${error}`));
    }
    for (const [index, curriculum] of dataset.curricula.entries()) {
      errors.push(...validateCurriculum(curriculum).map((error) => `curriculum ${index}: ${error}`));
    }
    for (const document of dataset.provenance) errors.push(...validateProvenance(document, inventory));
    if (errors.length) return errors;
    if (requireContent && (!dataset.catalogs.length || !dataset.curricula.length)) {
      errors.push('content foundation incomplete: at least one catalog and curriculum are required');
    }

    const content = new Map();
    function register(item, type) {
      if (content.has(item.id)) errors.push(`${item.id}: duplicate content ID across catalogs/curricula`);
      else content.set(item.id, { item, type });
    }
    for (const catalog of dataset.catalogs) {
      for (const item of catalog.items) register(item, catalog.catalog_type);
    }
    for (const curriculum of dataset.curricula) register(curriculum, 'gup');

    const citations = new Map();
    const locations = new Set();
    for (const citation of dataset.provenance.flatMap((document) => document.citations)) {
      if (citations.has(citation.id)) errors.push(`duplicate citation ID across files: ${citation.id}`);
      citations.set(citation.id, citation);
      const location = JSON.stringify([citation.content_id, citation.source_id, citation.pdf_page, citation.section]);
      if (locations.has(location)) errors.push(`duplicate citation location across files: ${citation.id}`);
      locations.add(location);
      if (!content.has(citation.content_id)) errors.push(`${citation.id}: unknown content_id ${citation.content_id}`);
    }

    const usedCitations = new Set();
    function checkCitations(ids, owner, context) {
      for (const id of ids) {
        const citation = citations.get(id);
        if (!citation) errors.push(`${context}: unknown citation ID ${id}`);
        else if (citation.content_id !== owner) errors.push(`${context}: citation ${id} belongs to another content`);
        else usedCitations.add(id);
      }
    }
    function checkReference(id, type, context) {
      if (content.get(id)?.type !== type) errors.push(`${context}: missing or wrong-type ${type} reference ${id}`);
    }
    for (const { item, type } of content.values()) {
      checkCitations(item.citation_ids, item.id, item.id);
      if (type === 'position' && item.biomechanics?.weight) {
        const { front_percent: front, rear_percent: rear } = item.biomechanics.weight;
        if (Math.abs(front + rear - 100) > 1e-9) errors.push(`${item.id}: weight percentages must sum to 100`);
      }
      if (type === 'tul') {
        if (!item.sequence_complete && item.steps.length && !item.sequence_scope) {
          errors.push(`${item.id}: partial steps require an explicit sequence_scope`);
        }
        if (item.initial_position_id !== null) checkReference(item.initial_position_id, 'position', item.id);
        let previous = 0;
        for (const step of item.steps) {
          if (step.step_number <= previous) errors.push(`${item.id}: steps must be strictly increasing and unique`);
          if (item.movement_count !== null && step.step_number > item.movement_count) {
            errors.push(`${item.id}: step exceeds declared movement_count`);
          }
          previous = step.step_number;
          checkReference(step.position_id, 'position', `${item.id} step ${step.step_number}`);
          checkCitations(step.citation_ids, item.id, `${item.id} step ${step.step_number}`);
        }
        if (item.sequence_complete && (item.movement_count === null || item.initial_position_id === null
          || item.steps.length !== item.movement_count
          || item.steps.some((step, index) => step.step_number !== index + 1))) {
          errors.push(`${item.id}: complete sequence requires known count/initial position and contiguous steps`);
        }
      }
      if (type === 'gup') {
        if (item.id !== `gup_${item.gup}`) errors.push(`${item.id}: ID must match gup_${item.gup}`);
        let requirements = 0;
        for (const [field, ids] of Object.entries(item.requirements)) {
          for (const id of ids) checkReference(id, field.slice(0, -4), `${item.id} ${field}`);
          requirements += ids.length;
        }
        if (!requirements) errors.push(`${item.id}: curriculum has no requirements`);
      }
    }
    for (const id of citations.keys()) {
      if (!usedCitations.has(id)) errors.push(`${id}: citation is not linked by its content`);
    }
    return errors;
  }

  return { validateCatalog, validateCurriculum, validateDataset };
}
