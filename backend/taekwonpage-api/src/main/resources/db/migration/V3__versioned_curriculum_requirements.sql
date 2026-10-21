-- Draft requirements only. Neither baseline nor revision is school approval.
CREATE FUNCTION curriculum_requirement_groups()
RETURNS TABLE(field_name text, relation_name text, column_name text, required_type text)
LANGUAGE sql IMMUTABLE AS $$
    VALUES ('position_ids', 'gup_position', 'position_id', 'position'),
           ('theory_ids', 'gup_theory', 'theory_id', 'theory'),
           ('vocabulary_ids', 'gup_vocabulary', 'vocabulary_id', 'vocabulary'),
           ('body_tool_ids', 'gup_tool', 'tool_id', 'body_tool'),
           ('kick_ids', 'gup_kick', 'kick_id', 'kick'),
           ('tul_ids', 'gup_tul', 'tul_id', 'tul'),
           ('combat_ids', 'gup_combat', 'combat_id', 'combat');
$$;

CREATE FUNCTION normalize_curriculum_requirements(requirements jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    group_info record;
    normalized jsonb := '{}'::jsonb;
    sorted_ids jsonb;
    total integer := 0;
BEGIN
    IF jsonb_typeof(requirements) IS DISTINCT FROM 'object' THEN
        RAISE EXCEPTION 'requirements must be an object' USING ERRCODE = '22023';
    END IF;
    IF (SELECT count(*) FROM jsonb_object_keys(requirements)) <> 7 THEN
        RAISE EXCEPTION 'requirements must contain exactly seven groups' USING ERRCODE = '22023';
    END IF;
    FOR group_info IN SELECT * FROM curriculum_requirement_groups() LOOP
        IF jsonb_typeof(requirements->group_info.field_name) IS DISTINCT FROM 'array' THEN
            RAISE EXCEPTION 'missing or invalid requirement group' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM jsonb_array_elements(requirements->group_info.field_name) item
            WHERE jsonb_typeof(item) <> 'string') THEN
            RAISE EXCEPTION 'requirement IDs must be strings' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(requirements->group_info.field_name) item
            WHERE item !~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' OR item ~ '[[:space:]]')
            OR (SELECT count(DISTINCT item) FROM jsonb_array_elements_text(requirements->group_info.field_name) item)
                <> jsonb_array_length(requirements->group_info.field_name) THEN
            RAISE EXCEPTION 'requirement IDs must be canonical and unique' USING ERRCODE = '22023';
        END IF;
        SELECT COALESCE(jsonb_agg(item ORDER BY item COLLATE "C"), '[]'::jsonb) INTO sorted_ids
            FROM jsonb_array_elements_text(requirements->group_info.field_name) item;
        normalized := normalized || jsonb_build_object(group_info.field_name, sorted_ids);
        total := total + jsonb_array_length(sorted_ids);
    END LOOP;
    IF total = 0 THEN RAISE EXCEPTION 'curriculum has no requirements' USING ERRCODE = '22023'; END IF;
    RETURN normalized;
END;
$$;

CREATE FUNCTION curriculum_requirements_snapshot(target_id canonical_id) RETURNS jsonb
LANGUAGE plpgsql STABLE AS $$
DECLARE
    group_info record;
    snapshot jsonb := '{}'::jsonb;
    ids jsonb;
BEGIN
    FOR group_info IN SELECT * FROM curriculum_requirement_groups() LOOP
        -- Identifiers come exclusively from the fixed mapping above; values are bound.
        EXECUTE format('SELECT COALESCE(jsonb_agg(%I ORDER BY %I COLLATE "C"), ''[]''::jsonb) FROM %I WHERE gup_id = $1',
            group_info.column_name, group_info.column_name, group_info.relation_name) INTO ids USING target_id;
        snapshot := snapshot || jsonb_build_object(group_info.field_name, ids);
    END LOOP;
    RETURN snapshot;
END;
$$;

CREATE TABLE curriculum_draft_revision (
    content_id canonical_id NOT NULL REFERENCES gup (id),
    revision bigint NOT NULL CHECK (revision >= 0),
    previous_revision bigint,
    old_requirements jsonb,
    new_requirements jsonb NOT NULL CHECK (jsonb_typeof(new_requirements) = 'object'),
    citation_snapshot jsonb NOT NULL CHECK (jsonb_typeof(citation_snapshot) = 'array'),
    reason text NOT NULL CHECK (reason ~ '\S'),
    operator_reference text NOT NULL CHECK (operator_reference ~ '\S'),
    operator_verification text NOT NULL DEFAULT 'unverified_local_reference'
        CHECK (operator_verification = 'unverified_local_reference'),
    database_actor text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CHECK ((revision = 0 AND previous_revision IS NULL AND old_requirements IS NULL)
        OR (revision > 0 AND previous_revision IS NOT NULL AND previous_revision = revision - 1
            AND old_requirements IS NOT NULL AND jsonb_typeof(old_requirements) = 'object'
            AND old_requirements <> new_requirements AND jsonb_array_length(citation_snapshot) > 0)),
    PRIMARY KEY (content_id, revision)
);

CREATE FUNCTION guard_curriculum_revision_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    entry content_entry%ROWTYPE;
    requirements jsonb;
    citations jsonb;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id FOR UPDATE;
    IF NOT FOUND OR entry.content_type <> 'gup' OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'curriculum revision requires a draft Gup' USING ERRCODE = '55000';
    END IF;
    requirements := curriculum_requirements_snapshot(NEW.content_id);
    SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.id), '[]'::jsonb) INTO citations
        FROM content_source c WHERE c.content_id = NEW.content_id;
    IF NEW.citation_snapshot IS DISTINCT FROM citations THEN
        RAISE EXCEPTION 'curriculum citation snapshot mismatch' USING ERRCODE = '55000';
    END IF;
    IF NEW.revision = 0 THEN
        IF entry.draft_revision <> 0 OR NEW.new_requirements IS DISTINCT FROM requirements THEN
            RAISE EXCEPTION 'curriculum baseline mismatch' USING ERRCODE = '55000';
        END IF;
    ELSE
        IF entry.draft_revision IS DISTINCT FROM NEW.previous_revision
            OR NEW.old_requirements IS DISTINCT FROM requirements
            OR NEW.new_requirements IS DISTINCT FROM normalize_curriculum_requirements(NEW.new_requirements) THEN
            RAISE EXCEPTION 'curriculum revision mismatch' USING ERRCODE = '55000';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER curriculum_revision_insert BEFORE INSERT ON curriculum_draft_revision
    FOR EACH ROW EXECUTE FUNCTION guard_curriculum_revision_insert();
CREATE TRIGGER curriculum_history_immutable BEFORE UPDATE OR DELETE ON curriculum_draft_revision
    FOR EACH ROW EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER curriculum_history_no_truncate BEFORE TRUNCATE ON curriculum_draft_revision
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE FUNCTION assert_curriculum_revision_applied(target_id canonical_id) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    revision_number bigint;
    latest curriculum_draft_revision%ROWTYPE;
BEGIN
    SELECT draft_revision INTO revision_number FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT * INTO latest FROM curriculum_draft_revision WHERE content_id = target_id ORDER BY revision DESC LIMIT 1;
    IF NOT FOUND OR revision_number IS DISTINCT FROM latest.revision
        OR curriculum_requirements_snapshot(target_id) IS DISTINCT FROM latest.new_requirements THEN
        RAISE EXCEPTION 'curriculum changes require an applied revision' USING ERRCODE = '55000';
    END IF;
END;
$$;

CREATE FUNCTION check_curriculum_revision_applied() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM assert_curriculum_revision_applied(NEW.content_id);
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER curriculum_revision_applied AFTER INSERT ON curriculum_draft_revision
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_curriculum_revision_applied();

CREATE FUNCTION capture_curriculum_baseline() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO curriculum_draft_revision(content_id, revision, new_requirements, citation_snapshot, reason, operator_reference)
    SELECT NEW.id, 0, curriculum_requirements_snapshot(NEW.id),
        COALESCE((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) FROM content_source c WHERE c.content_id = NEW.id), '[]'::jsonb),
        'Initial local draft baseline; not approval.', 'local_database_baseline';
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER curriculum_baseline_capture AFTER INSERT ON gup
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION capture_curriculum_baseline();

CREATE FUNCTION check_curriculum_requirement_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN PERFORM assert_curriculum_revision_applied(OLD.gup_id); END IF;
    IF TG_OP <> 'DELETE' THEN PERFORM assert_curriculum_revision_applied(NEW.gup_id); END IF;
    RETURN NULL;
END;
$$;
DO $$
DECLARE group_info record;
BEGIN
    FOR group_info IN SELECT * FROM curriculum_requirement_groups() LOOP
        EXECUTE format('CREATE CONSTRAINT TRIGGER curriculum_requirements_consistent AFTER INSERT OR UPDATE OR DELETE ON %I DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_curriculum_requirement_change()', group_info.relation_name);
        EXECUTE format('CREATE TRIGGER curriculum_requirements_no_truncate BEFORE TRUNCATE ON %I FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite()', group_info.relation_name);
    END LOOP;
END;
$$;

-- Extend V2's guard without changing the previously applied migration.
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
    ELSIF NOT EXISTS (SELECT 1 FROM content_draft_revision r WHERE r.content_id = OLD.id
        AND r.revision = NEW.draft_revision AND r.previous_revision = OLD.draft_revision
        AND r.old_name = OLD.name AND r.old_description = OLD.description
        AND r.new_name = NEW.name AND r.new_description = NEW.description) THEN
        RAISE EXCEPTION 'content changes require a matching draft revision' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION revise_curriculum_draft(target_id canonical_id, expected_revision bigint,
    replacement_requirements jsonb, change_reason text, local_operator_reference text)
RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE
    entry content_entry%ROWTYPE;
    before_requirements jsonb;
    after_requirements jsonb;
    citations jsonb;
    group_info record;
BEGIN
    IF expected_revision IS NULL OR expected_revision < 0
        OR NOT COALESCE(change_reason ~ '\S', false) OR NOT COALESCE(local_operator_reference ~ '\S', false) THEN
        RAISE EXCEPTION 'invalid curriculum edit parameters' USING ERRCODE = '22023';
    END IF;
    after_requirements := normalize_curriculum_requirements(replacement_requirements);
    LOCK TABLE content_entry IN ROW EXCLUSIVE MODE;
    LOCK TABLE content_source IN SHARE MODE;
    LOCK TABLE gup_position, gup_theory, gup_vocabulary, gup_tool, gup_kick, gup_tul, gup_combat IN SHARE ROW EXCLUSIVE MODE;
    SELECT * INTO entry FROM content_entry WHERE id = target_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'curriculum not found' USING ERRCODE = 'P0002'; END IF;
    IF entry.content_type <> 'gup' OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'entry is not a draft curriculum' USING ERRCODE = '55000';
    END IF;
    IF entry.draft_revision <> expected_revision THEN
        RAISE EXCEPTION 'stale curriculum revision' USING ERRCODE = '40001';
    END IF;
    PERFORM assert_curriculum_revision_applied(target_id);
    before_requirements := curriculum_requirements_snapshot(target_id);
    IF before_requirements = after_requirements THEN
        RAISE EXCEPTION 'curriculum edit has no changes' USING ERRCODE = '22023';
    END IF;
    FOR group_info IN SELECT * FROM curriculum_requirement_groups() LOOP
        IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(after_requirements->group_info.field_name) required_id
            WHERE NOT EXISTS (SELECT 1 FROM content_entry c WHERE c.id = required_id AND c.content_type = group_info.required_type)) THEN
            RAISE EXCEPTION 'missing or wrong-type curriculum reference' USING ERRCODE = '23503';
        END IF;
    END LOOP;
    SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) INTO citations FROM content_source c WHERE c.content_id = target_id;
    IF citations IS NULL THEN RAISE EXCEPTION 'curriculum edit requires citations' USING ERRCODE = '55000'; END IF;
    SET CONSTRAINTS curriculum_revision_applied, curriculum_requirements_consistent DEFERRED;
    INSERT INTO curriculum_draft_revision(content_id, revision, previous_revision, old_requirements,
        new_requirements, citation_snapshot, reason, operator_reference)
    VALUES (target_id, expected_revision + 1, expected_revision, before_requirements, after_requirements,
        citations, change_reason, local_operator_reference);
    FOR group_info IN SELECT * FROM curriculum_requirement_groups() LOOP
        EXECUTE format('DELETE FROM %I WHERE gup_id = $1', group_info.relation_name) USING target_id;
        EXECUTE format('INSERT INTO %I(gup_id, %I) SELECT $1, item::canonical_id FROM jsonb_array_elements_text($2) item',
            group_info.relation_name, group_info.column_name) USING target_id, after_requirements->group_info.field_name;
    END LOOP;
    UPDATE content_entry SET draft_revision = expected_revision + 1 WHERE id = target_id;
    SET CONSTRAINTS curriculum_revision_applied, curriculum_requirements_consistent IMMEDIATE;
    RETURN expected_revision + 1;
END;
$$;

-- Existing Gups receive an observed baseline, never a fabricated approval.
INSERT INTO curriculum_draft_revision(content_id, revision, new_requirements, citation_snapshot, reason, operator_reference)
SELECT g.id, 0, curriculum_requirements_snapshot(g.id),
    COALESCE((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) FROM content_source c WHERE c.content_id = g.id), '[]'::jsonb),
    'Observed local draft baseline at V3 migration; not approval.', 'local_database_baseline'
FROM gup g;

REVOKE ALL ON TABLE curriculum_draft_revision FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION revise_curriculum_draft(canonical_id, bigint, jsonb, text, text) FROM PUBLIC;
