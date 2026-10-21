-- Subtype details only; no martial approval, source changes or publication.
CREATE FUNCTION normalize_catalog_details(kind text, details jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    field_name text;
    front_weight numeric;
    rear_weight numeric;
    front_rotation numeric;
    rear_rotation numeric;
BEGIN
    IF jsonb_typeof(details) IS DISTINCT FROM 'object' THEN
        RAISE EXCEPTION 'catalog details must be an object' USING ERRCODE = '22023';
    END IF;
    IF kind = 'position' THEN
        IF (SELECT count(*) FROM jsonb_object_keys(details)) <> 4
            OR NOT details ?& ARRAY['front_percent', 'rear_percent', 'front_rotation_deg', 'rear_rotation_deg'] THEN
            RAISE EXCEPTION 'position details require exactly four numeric/null fields' USING ERRCODE = '22023';
        END IF;
        FOREACH field_name IN ARRAY ARRAY['front_percent', 'rear_percent', 'front_rotation_deg', 'rear_rotation_deg'] LOOP
            IF jsonb_typeof(details->field_name) NOT IN ('number', 'null') THEN
                RAISE EXCEPTION 'position values must be numeric or null' USING ERRCODE = '22023';
            END IF;
        END LOOP;
        front_weight := (details->>'front_percent')::numeric;
        rear_weight := (details->>'rear_percent')::numeric;
        front_rotation := (details->>'front_rotation_deg')::numeric;
        rear_rotation := (details->>'rear_rotation_deg')::numeric;
        IF (front_weight IS NULL) <> (rear_weight IS NULL)
            OR front_weight < 0 OR front_weight > 100 OR rear_weight < 0 OR rear_weight > 100
            OR front_weight + rear_weight <> 100
            OR front_rotation < 0 OR front_rotation >= 360 OR rear_rotation < 0 OR rear_rotation >= 360 THEN
            RAISE EXCEPTION 'invalid position weights or rotations' USING ERRCODE = '22023';
        END IF;
        RETURN jsonb_build_object('front_percent', front_weight, 'rear_percent', rear_weight,
            'front_rotation_deg', front_rotation, 'rear_rotation_deg', rear_rotation);
    ELSIF kind = 'vocabulary' THEN
        IF (SELECT count(*) FROM jsonb_object_keys(details)) <> 2 OR NOT details ?& ARRAY['translation', 'aliases']
            OR jsonb_typeof(details->'translation') IS DISTINCT FROM 'string'
            OR NOT COALESCE(details->>'translation' ~ '\S', false)
            OR jsonb_typeof(details->'aliases') IS DISTINCT FROM 'array' THEN
            RAISE EXCEPTION 'invalid vocabulary details' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM jsonb_array_elements(details->'aliases') item
            WHERE jsonb_typeof(item) <> 'string' OR NOT COALESCE(item #>> '{}' ~ '\S', false))
            OR (SELECT count(DISTINCT item) FROM jsonb_array_elements(details->'aliases') item)
                <> jsonb_array_length(details->'aliases') THEN
            RAISE EXCEPTION 'aliases must be unique nonblank strings' USING ERRCODE = '22023';
        END IF;
        RETURN jsonb_build_object('translation', details->'translation', 'aliases', details->'aliases');
    END IF;
    RAISE EXCEPTION 'unsupported catalog detail type' USING ERRCODE = '22023';
END;
$$;

CREATE FUNCTION catalog_details_snapshot(target_id canonical_id, kind text) RETURNS jsonb
LANGUAGE plpgsql STABLE AS $$
DECLARE snapshot jsonb;
BEGIN
    IF kind = 'position' THEN
        SELECT jsonb_build_object('front_percent', front_percent, 'rear_percent', rear_percent,
            'front_rotation_deg', front_rotation_deg, 'rear_rotation_deg', rear_rotation_deg)
            INTO snapshot FROM position WHERE id = target_id;
    ELSIF kind = 'vocabulary' THEN
        SELECT jsonb_build_object('translation', translation, 'aliases', aliases)
            INTO snapshot FROM vocabulary WHERE id = target_id;
    ELSE
        RAISE EXCEPTION 'unsupported catalog detail type' USING ERRCODE = '22023';
    END IF;
    RETURN snapshot;
END;
$$;

CREATE TABLE content_detail_revision (
    content_id canonical_id NOT NULL,
    content_type text NOT NULL CHECK (content_type IN ('position', 'vocabulary')),
    revision bigint NOT NULL CHECK (revision >= 0),
    is_baseline boolean NOT NULL DEFAULT false,
    previous_revision bigint,
    old_details jsonb,
    new_details jsonb NOT NULL CHECK (jsonb_typeof(new_details) = 'object'),
    citation_snapshot jsonb NOT NULL CHECK (jsonb_typeof(citation_snapshot) = 'array'),
    reason text NOT NULL CHECK (reason ~ '\S'),
    operator_reference text NOT NULL CHECK (operator_reference ~ '\S'),
    operator_verification text NOT NULL DEFAULT 'unverified_local_reference'
        CHECK (operator_verification = 'unverified_local_reference'),
    database_actor text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CHECK ((is_baseline AND previous_revision IS NULL AND old_details IS NULL)
        OR (NOT is_baseline AND revision > 0 AND previous_revision IS NOT NULL AND previous_revision = revision - 1
            AND old_details IS NOT NULL AND jsonb_typeof(old_details) = 'object'
            AND old_details <> new_details AND jsonb_array_length(citation_snapshot) > 0)),
    FOREIGN KEY (content_id, content_type) REFERENCES content_entry (id, content_type),
    PRIMARY KEY (content_id, revision)
);
CREATE UNIQUE INDEX one_detail_baseline_idx ON content_detail_revision(content_id) WHERE is_baseline;

CREATE FUNCTION assert_content_revision_chain(target_id canonical_id) RETURNS void LANGUAGE plpgsql AS $$
DECLARE expected bigint; total bigint; distinct_total bigint; highest bigint;
BEGIN
    SELECT draft_revision INTO expected FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT count(*), count(DISTINCT revision), COALESCE(max(revision), 0) INTO total, distinct_total, highest FROM (
        SELECT revision FROM content_draft_revision WHERE content_id = target_id
        UNION ALL SELECT revision FROM curriculum_draft_revision WHERE content_id = target_id AND revision > 0
        UNION ALL SELECT revision FROM content_detail_revision WHERE content_id = target_id AND NOT is_baseline
    ) events;
    IF total <> expected OR distinct_total <> expected OR highest <> expected THEN
        RAISE EXCEPTION 'draft revision chain is incomplete or duplicated' USING ERRCODE = '55000';
    END IF;
END;
$$;

CREATE FUNCTION guard_detail_revision_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE entry content_entry%ROWTYPE; details jsonb; citations jsonb;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id FOR UPDATE;
    IF NOT FOUND OR entry.content_type <> NEW.content_type OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'detail revision requires matching draft subtype' USING ERRCODE = '55000';
    END IF;
    details := catalog_details_snapshot(NEW.content_id, NEW.content_type);
    SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.id), '[]'::jsonb) INTO citations
        FROM content_source c WHERE c.content_id = NEW.content_id;
    IF details IS NULL OR NEW.citation_snapshot IS DISTINCT FROM citations THEN
        RAISE EXCEPTION 'detail revision subtype or citation snapshot mismatch' USING ERRCODE = '55000';
    END IF;
    IF NEW.is_baseline THEN
        IF NEW.revision <> entry.draft_revision OR NEW.new_details IS DISTINCT FROM details THEN
            RAISE EXCEPTION 'detail baseline mismatch' USING ERRCODE = '55000';
        END IF;
    ELSIF NEW.previous_revision IS DISTINCT FROM entry.draft_revision OR NEW.old_details IS DISTINCT FROM details
        OR NEW.new_details IS DISTINCT FROM normalize_catalog_details(NEW.content_type, NEW.new_details) THEN
        RAISE EXCEPTION 'detail revision mismatch' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER detail_revision_insert BEFORE INSERT ON content_detail_revision
    FOR EACH ROW EXECUTE FUNCTION guard_detail_revision_insert();
CREATE TRIGGER detail_history_immutable BEFORE UPDATE OR DELETE ON content_detail_revision
    FOR EACH ROW EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER detail_history_no_truncate BEFORE TRUNCATE ON content_detail_revision
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE FUNCTION assert_catalog_details_applied(target_id canonical_id) RETURNS void LANGUAGE plpgsql AS $$
DECLARE entry content_entry%ROWTYPE; latest content_detail_revision%ROWTYPE;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT * INTO latest FROM content_detail_revision WHERE content_id = target_id ORDER BY revision DESC LIMIT 1;
    IF NOT FOUND OR entry.draft_revision < latest.revision
        OR catalog_details_snapshot(target_id, entry.content_type) IS DISTINCT FROM latest.new_details THEN
        RAISE EXCEPTION 'catalog detail changes require an applied revision' USING ERRCODE = '55000';
    END IF;
    PERFORM assert_content_revision_chain(target_id);
END;
$$;
CREATE FUNCTION check_detail_revision_applied() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM assert_catalog_details_applied(NEW.content_id);
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER detail_revision_applied AFTER INSERT ON content_detail_revision
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_detail_revision_applied();

CREATE FUNCTION capture_detail_baseline() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO content_detail_revision(content_id, content_type, revision, is_baseline, new_details,
        citation_snapshot, reason, operator_reference)
    SELECT c.id, c.content_type, c.draft_revision, true, catalog_details_snapshot(c.id, c.content_type),
        COALESCE((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.id) FROM content_source s WHERE s.content_id = c.id), '[]'::jsonb),
        'Observed local draft subtype baseline; not approval.', 'local_database_baseline'
        FROM content_entry c WHERE c.id = NEW.id;
    RETURN NULL;
END;
$$;
CREATE FUNCTION check_catalog_detail_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    -- Initial construction may follow an editor that made constraints immediate.
    -- The pending baseline trigger still validates this new subtype at commit.
    IF TG_OP = 'INSERT' AND NOT EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = NEW.id) THEN
        RETURN NULL;
    END IF;
    IF TG_OP <> 'INSERT' THEN PERFORM assert_catalog_details_applied(OLD.id); END IF;
    IF TG_OP <> 'DELETE' THEN PERFORM assert_catalog_details_applied(NEW.id); END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER a_position_detail_baseline AFTER INSERT ON position
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION capture_detail_baseline();
CREATE CONSTRAINT TRIGGER a_vocabulary_detail_baseline AFTER INSERT ON vocabulary
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION capture_detail_baseline();
CREATE CONSTRAINT TRIGGER catalog_details_consistent AFTER INSERT OR UPDATE OR DELETE ON position
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_catalog_detail_change();
CREATE CONSTRAINT TRIGGER catalog_details_consistent AFTER INSERT OR UPDATE OR DELETE ON vocabulary
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_catalog_detail_change();
CREATE TRIGGER position_details_no_truncate BEFORE TRUNCATE ON position
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER vocabulary_details_no_truncate BEFORE TRUNCATE ON vocabulary
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE OR REPLACE FUNCTION guard_draft_entry_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW IS NOT DISTINCT FROM OLD THEN RETURN NEW; END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.content_type IS DISTINCT FROM OLD.content_type
        OR NEW.review_status IS DISTINCT FROM OLD.review_status OR NEW.draft_revision <> OLD.draft_revision + 1 THEN
        RAISE EXCEPTION 'content changes require a matching draft revision' USING ERRCODE = '55000';
    END IF;
    IF OLD.content_type = 'gup' THEN
        IF NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description
            OR NOT EXISTS (SELECT 1 FROM curriculum_draft_revision r WHERE r.content_id = OLD.id
                AND r.revision = NEW.draft_revision AND r.previous_revision = OLD.draft_revision) THEN
            RAISE EXCEPTION 'Gup changes require a matching curriculum revision' USING ERRCODE = '55000';
        END IF;
    ELSIF EXISTS (SELECT 1 FROM content_detail_revision r WHERE r.content_id = OLD.id AND NOT r.is_baseline
        AND r.revision = NEW.draft_revision AND r.previous_revision = OLD.draft_revision) THEN
        IF NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description THEN
            RAISE EXCEPTION 'detail edits cannot change generic text' USING ERRCODE = '55000';
        END IF;
    ELSIF NOT EXISTS (SELECT 1 FROM content_draft_revision r WHERE r.content_id = OLD.id
        AND r.revision = NEW.draft_revision AND r.previous_revision = OLD.draft_revision
        AND r.old_name = OLD.name AND r.old_description = OLD.description
        AND r.new_name = NEW.name AND r.new_description = NEW.description) THEN
        RAISE EXCEPTION 'content changes require a matching draft revision' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION check_draft_revision_applied() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE entry content_entry%ROWTYPE; latest content_draft_revision%ROWTYPE;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id;
    SELECT * INTO latest FROM content_draft_revision WHERE content_id = NEW.content_id ORDER BY revision DESC LIMIT 1;
    IF entry.name IS DISTINCT FROM latest.new_name OR entry.description IS DISTINCT FROM latest.new_description THEN
        RAISE EXCEPTION 'draft history has an unapplied revision' USING ERRCODE = '55000';
    END IF;
    PERFORM assert_content_revision_chain(NEW.content_id);
    RETURN NULL;
END;
$$;

CREATE FUNCTION revise_catalog_details(target_id canonical_id, expected_revision bigint, expected_type text,
    replacement_details jsonb, change_reason text, local_operator_reference text)
RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE entry content_entry%ROWTYPE; before_details jsonb; after_details jsonb; citations jsonb;
BEGIN
    IF expected_revision IS NULL OR expected_revision < 0 OR NOT COALESCE(change_reason ~ '\S', false)
        OR NOT COALESCE(local_operator_reference ~ '\S', false) THEN
        RAISE EXCEPTION 'invalid detail edit parameters' USING ERRCODE = '22023';
    END IF;
    after_details := normalize_catalog_details(expected_type, replacement_details);
    LOCK TABLE content_entry IN ROW EXCLUSIVE MODE;
    LOCK TABLE content_source IN SHARE MODE;
    LOCK TABLE position, vocabulary IN SHARE ROW EXCLUSIVE MODE;
    SELECT * INTO entry FROM content_entry WHERE id = target_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'catalog entry not found' USING ERRCODE = 'P0002'; END IF;
    IF entry.content_type <> expected_type OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'entry is outside requested detail edit scope' USING ERRCODE = '55000';
    END IF;
    IF entry.draft_revision <> expected_revision THEN
        RAISE EXCEPTION 'stale catalog detail revision' USING ERRCODE = '40001';
    END IF;
    PERFORM assert_catalog_details_applied(target_id);
    before_details := catalog_details_snapshot(target_id, expected_type);
    IF before_details = after_details THEN RAISE EXCEPTION 'detail edit has no changes' USING ERRCODE = '22023'; END IF;
    SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) INTO citations FROM content_source c WHERE c.content_id = target_id;
    IF citations IS NULL THEN RAISE EXCEPTION 'detail edit requires citations' USING ERRCODE = '55000'; END IF;
    SET CONSTRAINTS detail_revision_applied, catalog_details_consistent DEFERRED;
    INSERT INTO content_detail_revision(content_id, content_type, revision, previous_revision, old_details,
        new_details, citation_snapshot, reason, operator_reference)
    VALUES (target_id, expected_type, expected_revision + 1, expected_revision, before_details,
        after_details, citations, change_reason, local_operator_reference);
    IF expected_type = 'position' THEN
        UPDATE position SET front_percent = (after_details->>'front_percent')::numeric,
            rear_percent = (after_details->>'rear_percent')::numeric,
            front_rotation_deg = (after_details->>'front_rotation_deg')::numeric,
            rear_rotation_deg = (after_details->>'rear_rotation_deg')::numeric WHERE id = target_id;
    ELSE
        UPDATE vocabulary SET translation = after_details->>'translation',
            aliases = ARRAY(SELECT jsonb_array_elements_text(after_details->'aliases')) WHERE id = target_id;
    END IF;
    UPDATE content_entry SET draft_revision = expected_revision + 1 WHERE id = target_id;
    SET CONSTRAINTS detail_revision_applied, catalog_details_consistent IMMEDIATE;
    RETURN expected_revision + 1;
END;
$$;

INSERT INTO content_detail_revision(content_id, content_type, revision, is_baseline, new_details,
    citation_snapshot, reason, operator_reference)
SELECT c.id, c.content_type, c.draft_revision, true, catalog_details_snapshot(c.id, c.content_type),
    COALESCE((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.id) FROM content_source s WHERE s.content_id = c.id), '[]'::jsonb),
    'Observed subtype baseline at V4 migration; not approval.', 'local_database_baseline'
FROM content_entry c WHERE c.content_type IN ('position', 'vocabulary');

REVOKE ALL ON TABLE content_detail_revision FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION revise_catalog_details(canonical_id, bigint, text, jsonb, text, text) FROM PUBLIC;
