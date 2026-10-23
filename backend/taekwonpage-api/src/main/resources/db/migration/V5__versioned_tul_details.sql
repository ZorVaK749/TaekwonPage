-- Explicit draft exercise edits, not inferred martial sequences or publication.
ALTER TABLE content_detail_revision DROP CONSTRAINT content_detail_revision_content_type_check;
ALTER TABLE content_detail_revision ADD CONSTRAINT content_detail_revision_content_type_check
    CHECK (content_type IN ('position', 'vocabulary', 'tul'));

CREATE FUNCTION normalize_tul_details(details jsonb) RETURNS jsonb LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    total integer;
    number integer;
    previous integer := 0;
    ordinal integer := 0;
    complete boolean;
    step jsonb;
    normalized_steps jsonb := '[]'::jsonb;
    citations jsonb;
BEGIN
    IF jsonb_typeof(details) IS DISTINCT FROM 'object' THEN
        RAISE EXCEPTION 'exercise details must be an object' USING ERRCODE = '22023';
    END IF;
    IF (SELECT count(*) FROM jsonb_object_keys(details)) <> 5
        OR NOT details ?& ARRAY['movement_count', 'initial_position_id', 'sequence_complete', 'sequence_scope', 'steps'] THEN
        RAISE EXCEPTION 'exercise details require exactly five fields' USING ERRCODE = '22023';
    END IF;
    IF jsonb_typeof(details->'movement_count') NOT IN ('number', 'null')
        OR jsonb_typeof(details->'initial_position_id') NOT IN ('string', 'null')
        OR jsonb_typeof(details->'sequence_complete') IS DISTINCT FROM 'boolean'
        OR jsonb_typeof(details->'sequence_scope') NOT IN ('string', 'null')
        OR jsonb_typeof(details->'steps') IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'invalid exercise detail types' USING ERRCODE = '22023';
    END IF;
    IF details->>'movement_count' IS NOT NULL THEN
        IF (details->>'movement_count')::numeric <> trunc((details->>'movement_count')::numeric)
            OR (details->>'movement_count')::numeric < 1 OR (details->>'movement_count')::numeric > 2147483647 THEN
            RAISE EXCEPTION 'invalid exercise count' USING ERRCODE = '22023';
        END IF;
        total := (details->>'movement_count')::numeric::integer;
    END IF;
    IF details->>'initial_position_id' IS NOT NULL AND
        (details->>'initial_position_id' !~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' OR details->>'initial_position_id' ~ '[[:space:]]') THEN
        RAISE EXCEPTION 'invalid initial position ID' USING ERRCODE = '22023';
    END IF;
    IF details->>'sequence_scope' IS NOT NULL AND NOT (details->>'sequence_scope' ~ '\S') THEN
        RAISE EXCEPTION 'invalid exercise scope' USING ERRCODE = '22023';
    END IF;
    complete := (details->>'sequence_complete')::boolean;
    IF NOT complete AND jsonb_array_length(details->'steps') > 0 AND details->>'sequence_scope' IS NULL THEN
        RAISE EXCEPTION 'partial steps require explicit scope' USING ERRCODE = '22023';
    END IF;
    FOR step IN SELECT value FROM jsonb_array_elements(details->'steps') LOOP
        IF jsonb_typeof(step) IS DISTINCT FROM 'object' THEN
            RAISE EXCEPTION 'invalid exercise step' USING ERRCODE = '22023';
        END IF;
        IF (SELECT count(*) FROM jsonb_object_keys(step)) <> 4
            OR NOT step ?& ARRAY['step_number', 'position_id', 'description', 'citation_ids']
            OR jsonb_typeof(step->'step_number') IS DISTINCT FROM 'number'
            OR jsonb_typeof(step->'position_id') IS DISTINCT FROM 'string'
            OR jsonb_typeof(step->'description') IS DISTINCT FROM 'string'
            OR NOT COALESCE(step->>'description' ~ '\S', false)
            OR jsonb_typeof(step->'citation_ids') IS DISTINCT FROM 'array' THEN
            RAISE EXCEPTION 'invalid step fields' USING ERRCODE = '22023';
        END IF;
        IF (step->>'step_number')::numeric <> trunc((step->>'step_number')::numeric)
            OR (step->>'step_number')::numeric < 1 OR (step->>'step_number')::numeric > 2147483647
            OR step->>'position_id' !~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' OR step->>'position_id' ~ '[[:space:]]' THEN
            RAISE EXCEPTION 'invalid step number or position ID' USING ERRCODE = '22023';
        END IF;
        number := (step->>'step_number')::numeric::integer;
        ordinal := ordinal + 1;
        IF number <= previous OR (total IS NOT NULL AND number > total) OR (complete AND number <> ordinal) THEN
            RAISE EXCEPTION 'steps must be increasing and within the declared sequence' USING ERRCODE = '22023';
        END IF;
        previous := number;
        IF jsonb_array_length(step->'citation_ids') = 0
            OR EXISTS (SELECT 1 FROM jsonb_array_elements(step->'citation_ids') item WHERE jsonb_typeof(item) <> 'string') THEN
            RAISE EXCEPTION 'step citations must be a nonempty ID list' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(step->'citation_ids') item
            WHERE item !~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' OR item ~ '[[:space:]]')
            OR (SELECT count(DISTINCT item) FROM jsonb_array_elements_text(step->'citation_ids') item)
                <> jsonb_array_length(step->'citation_ids') THEN
            RAISE EXCEPTION 'step citation IDs must be canonical and unique' USING ERRCODE = '22023';
        END IF;
        SELECT jsonb_agg(item ORDER BY item COLLATE "C") INTO citations FROM jsonb_array_elements_text(step->'citation_ids') item;
        normalized_steps := normalized_steps || jsonb_build_array(jsonb_build_object('step_number', number,
            'position_id', step->'position_id', 'description', step->'description', 'citation_ids', citations));
    END LOOP;
    IF complete AND (total IS NULL OR details->>'initial_position_id' IS NULL OR ordinal <> total) THEN
        RAISE EXCEPTION 'complete sequence requires known count, preparation and contiguous steps' USING ERRCODE = '22023';
    END IF;
    RETURN jsonb_build_object('movement_count', total, 'initial_position_id', details->'initial_position_id',
        'sequence_complete', complete, 'sequence_scope', details->'sequence_scope', 'steps', normalized_steps);
END;
$$;

CREATE OR REPLACE FUNCTION catalog_details_snapshot(target_id canonical_id, kind text) RETURNS jsonb
LANGUAGE plpgsql STABLE AS $$
DECLARE snapshot jsonb;
BEGIN
    IF kind = 'position' THEN
        SELECT jsonb_build_object('front_percent', front_percent, 'rear_percent', rear_percent,
            'front_rotation_deg', front_rotation_deg, 'rear_rotation_deg', rear_rotation_deg)
            INTO snapshot FROM position WHERE id = target_id;
    ELSIF kind = 'vocabulary' THEN
        SELECT jsonb_build_object('translation', translation, 'aliases', aliases) INTO snapshot FROM vocabulary WHERE id = target_id;
    ELSIF kind = 'tul' THEN
        SELECT jsonb_build_object('movement_count', t.movement_count, 'initial_position_id', t.initial_position_id,
            'sequence_complete', t.sequence_complete, 'sequence_scope', t.sequence_scope, 'steps',
            COALESCE((SELECT jsonb_agg(jsonb_build_object('step_number', s.step_number, 'position_id', s.position_id,
                'description', s.description, 'citation_ids', COALESCE((SELECT jsonb_agg(c.citation_id ORDER BY c.citation_id COLLATE "C")
                    FROM tul_step_source c WHERE c.tul_id = s.tul_id AND c.step_number = s.step_number), '[]'::jsonb)) ORDER BY s.step_number)
                FROM tul_step s WHERE s.tul_id = t.id), '[]'::jsonb)) INTO snapshot FROM tul t WHERE t.id = target_id;
    ELSE
        RAISE EXCEPTION 'unsupported catalog detail type' USING ERRCODE = '22023';
    END IF;
    RETURN snapshot;
END;
$$;

CREATE OR REPLACE FUNCTION guard_detail_revision_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE entry content_entry%ROWTYPE; details jsonb; citations jsonb; normalized jsonb;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id FOR UPDATE;
    IF NOT FOUND OR entry.content_type <> NEW.content_type OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'detail revision requires matching draft subtype' USING ERRCODE = '55000';
    END IF;
    details := catalog_details_snapshot(NEW.content_id, NEW.content_type);
    SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.id), '[]'::jsonb) INTO citations FROM content_source c WHERE c.content_id = NEW.content_id;
    IF details IS NULL OR NEW.citation_snapshot IS DISTINCT FROM citations THEN
        RAISE EXCEPTION 'detail revision subtype or citation snapshot mismatch' USING ERRCODE = '55000';
    END IF;
    IF NEW.is_baseline THEN
        IF NEW.revision <> entry.draft_revision OR NEW.new_details IS DISTINCT FROM details THEN
            RAISE EXCEPTION 'detail baseline mismatch' USING ERRCODE = '55000';
        END IF;
    ELSE
        normalized := CASE WHEN NEW.content_type = 'tul' THEN normalize_tul_details(NEW.new_details)
            ELSE normalize_catalog_details(NEW.content_type, NEW.new_details) END;
        IF NEW.previous_revision IS DISTINCT FROM entry.draft_revision OR NEW.old_details IS DISTINCT FROM details
            OR NEW.new_details IS DISTINCT FROM normalized THEN
            RAISE EXCEPTION 'detail revision mismatch' USING ERRCODE = '55000';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE CONSTRAINT TRIGGER a_tul_detail_baseline AFTER INSERT ON tul
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION capture_detail_baseline();
CREATE CONSTRAINT TRIGGER catalog_details_consistent AFTER INSERT OR UPDATE OR DELETE ON tul
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_catalog_detail_change();

CREATE FUNCTION check_tul_child_details() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NOT EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = NEW.tul_id) THEN RETURN NULL; END IF;
    IF TG_OP <> 'INSERT' THEN PERFORM assert_catalog_details_applied(OLD.tul_id); END IF;
    IF TG_OP <> 'DELETE' THEN PERFORM assert_catalog_details_applied(NEW.tul_id); END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER catalog_details_consistent AFTER INSERT OR UPDATE OR DELETE ON tul_step
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_tul_child_details();
CREATE CONSTRAINT TRIGGER catalog_details_consistent AFTER INSERT OR UPDATE OR DELETE ON tul_step_source
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_tul_child_details();
CREATE TRIGGER tul_details_no_truncate BEFORE TRUNCATE ON tul FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER tul_steps_no_truncate BEFORE TRUNCATE ON tul_step FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER tul_step_sources_no_truncate BEFORE TRUNCATE ON tul_step_source FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE FUNCTION revise_tul_draft(target_id canonical_id, expected_revision bigint, replacement_details jsonb,
    change_reason text, local_operator_reference text)
RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE entry content_entry%ROWTYPE; before_details jsonb; after_details jsonb; citations jsonb; step jsonb;
BEGIN
    IF expected_revision IS NULL OR expected_revision < 0 OR NOT COALESCE(change_reason ~ '\S', false)
        OR NOT COALESCE(local_operator_reference ~ '\S', false) THEN
        RAISE EXCEPTION 'invalid exercise edit parameters' USING ERRCODE = '22023';
    END IF;
    after_details := normalize_tul_details(replacement_details);
    LOCK TABLE content_entry IN ROW EXCLUSIVE MODE;
    LOCK TABLE content_source IN SHARE MODE;
    LOCK TABLE tul, tul_step, tul_step_source IN SHARE ROW EXCLUSIVE MODE;
    SELECT * INTO entry FROM content_entry WHERE id = target_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'exercise not found' USING ERRCODE = 'P0002'; END IF;
    IF entry.content_type <> 'tul' OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'entry is not a draft exercise' USING ERRCODE = '55000';
    END IF;
    IF entry.draft_revision <> expected_revision THEN RAISE EXCEPTION 'stale exercise revision' USING ERRCODE = '40001'; END IF;
    PERFORM assert_catalog_details_applied(target_id);
    before_details := catalog_details_snapshot(target_id, 'tul');
    IF before_details = after_details THEN RAISE EXCEPTION 'exercise edit has no changes' USING ERRCODE = '22023'; END IF;
    SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) INTO citations FROM content_source c WHERE c.content_id = target_id;
    IF citations IS NULL THEN RAISE EXCEPTION 'exercise edit requires citations' USING ERRCODE = '55000'; END IF;
    SET CONSTRAINTS detail_revision_applied, catalog_details_consistent, tul_sequence_consistency, tul_step_consistency DEFERRED;
    INSERT INTO content_detail_revision(content_id, content_type, revision, previous_revision, old_details,
        new_details, citation_snapshot, reason, operator_reference)
    VALUES (target_id, 'tul', expected_revision + 1, expected_revision, before_details, after_details,
        citations, change_reason, local_operator_reference);
    DELETE FROM tul_step_source WHERE tul_id = target_id;
    DELETE FROM tul_step WHERE tul_id = target_id;
    UPDATE tul SET movement_count = (after_details->>'movement_count')::integer,
        initial_position_id = (after_details->>'initial_position_id')::canonical_id,
        sequence_complete = (after_details->>'sequence_complete')::boolean,
        sequence_scope = after_details->>'sequence_scope' WHERE id = target_id;
    FOR step IN SELECT value FROM jsonb_array_elements(after_details->'steps') LOOP
        INSERT INTO tul_step(tul_id, step_number, position_id, description)
        VALUES (target_id, (step->>'step_number')::integer, (step->>'position_id')::canonical_id, step->>'description');
        INSERT INTO tul_step_source(tul_id, step_number, citation_id)
        SELECT target_id, (step->>'step_number')::integer, item::canonical_id FROM jsonb_array_elements_text(step->'citation_ids') item;
    END LOOP;
    UPDATE content_entry SET draft_revision = expected_revision + 1 WHERE id = target_id;
    SET CONSTRAINTS detail_revision_applied, catalog_details_consistent, tul_sequence_consistency, tul_step_consistency IMMEDIATE;
    RETURN expected_revision + 1;
END;
$$;

INSERT INTO content_detail_revision(content_id, content_type, revision, is_baseline, new_details,
    citation_snapshot, reason, operator_reference)
SELECT c.id, 'tul', c.draft_revision, true, catalog_details_snapshot(c.id, 'tul'),
    COALESCE((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.id) FROM content_source s WHERE s.content_id = c.id), '[]'::jsonb),
    'Observed exercise baseline at V5 migration; not approval.', 'local_database_baseline'
FROM content_entry c JOIN tul t ON t.id = c.id;
REVOKE EXECUTE ON FUNCTION revise_tul_draft(canonical_id, bigint, jsonb, text, text) FROM PUBLIC;
