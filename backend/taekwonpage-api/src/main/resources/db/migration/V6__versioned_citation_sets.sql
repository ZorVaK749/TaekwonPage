-- Documentary draft edits only. Source registry, approval and publication unchanged.
CREATE FUNCTION content_citations_snapshot(target_id canonical_id) RETURNS jsonb LANGUAGE sql STABLE AS $$
    SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.id COLLATE "C"), '[]'::jsonb)
    FROM content_source c WHERE c.content_id = target_id;
$$;

CREATE FUNCTION normalize_citation_set(target_id canonical_id, proposed jsonb) RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE citation jsonb; field_name text; page_number integer; normalized jsonb := '[]'::jsonb;
BEGIN
    IF jsonb_typeof(proposed) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'citations must be an array' USING ERRCODE = '22023';
    END IF;
    IF jsonb_array_length(proposed) = 0 THEN RAISE EXCEPTION 'citation edit cannot leave entry uncited' USING ERRCODE = '22023'; END IF;
    FOR citation IN SELECT value FROM jsonb_array_elements(proposed) LOOP
        IF jsonb_typeof(citation) IS DISTINCT FROM 'object' THEN
            RAISE EXCEPTION 'invalid citation object' USING ERRCODE = '22023';
        END IF;
        IF (SELECT count(*) FROM jsonb_object_keys(citation)) <> 9
            OR NOT citation ?& ARRAY['id','content_id','source_id','source_sha256','pdf_page','printed_page','section','notes','review_status'] THEN
            RAISE EXCEPTION 'citation must have exactly nine fields' USING ERRCODE = '22023';
        END IF;
        FOREACH field_name IN ARRAY ARRAY['id','content_id','source_id'] LOOP
            IF jsonb_typeof(citation->field_name) IS DISTINCT FROM 'string'
                OR citation->>field_name !~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' OR citation->>field_name ~ '[[:space:]]' THEN
                RAISE EXCEPTION 'invalid citation identity' USING ERRCODE = '22023';
            END IF;
        END LOOP;
        IF citation->>'content_id' IS DISTINCT FROM target_id::text
            OR jsonb_typeof(citation->'source_sha256') IS DISTINCT FROM 'string'
            OR citation->>'source_sha256' !~ '^[a-f0-9]{64}$'
            OR citation->>'review_status' IS DISTINCT FROM 'pending_human_review' THEN
            RAISE EXCEPTION 'citation owner, copy or status mismatch' USING ERRCODE = '22023';
        END IF;
        FOREACH field_name IN ARRAY ARRAY['printed_page','section','notes'] LOOP
            IF jsonb_typeof(citation->field_name) NOT IN ('string','null')
                OR (citation->>field_name IS NOT NULL AND NOT (citation->>field_name ~ '\S')) THEN
                RAISE EXCEPTION 'invalid nullable citation text' USING ERRCODE = '22023';
            END IF;
        END LOOP;
        page_number := NULL;
        IF jsonb_typeof(citation->'pdf_page') IS DISTINCT FROM 'null' THEN
            IF jsonb_typeof(citation->'pdf_page') IS DISTINCT FROM 'number' THEN
                RAISE EXCEPTION 'citation page must be numeric or null' USING ERRCODE = '22023';
            END IF;
            IF (citation->>'pdf_page')::numeric <> trunc((citation->>'pdf_page')::numeric)
                OR (citation->>'pdf_page')::numeric < 1 OR (citation->>'pdf_page')::numeric > 2147483647 THEN
                RAISE EXCEPTION 'invalid citation page' USING ERRCODE = '22023';
            END IF;
            page_number := (citation->>'pdf_page')::numeric::integer;
        END IF;
        IF page_number IS NULL AND citation->>'section' IS NULL THEN
            RAISE EXCEPTION 'citation requires PDF page or section' USING ERRCODE = '22023';
        END IF;
        normalized := normalized || jsonb_build_array(jsonb_build_object('id', citation->'id', 'content_id', target_id,
            'source_id', citation->'source_id', 'source_sha256', citation->'source_sha256', 'pdf_page', page_number,
            'printed_page', citation->'printed_page', 'section', citation->'section', 'notes', citation->'notes',
            'review_status', 'pending_human_review'));
    END LOOP;
    IF (SELECT count(DISTINCT value->>'id') FROM jsonb_array_elements(normalized)) <> jsonb_array_length(normalized)
        OR EXISTS (SELECT 1 FROM jsonb_array_elements(normalized) item
            GROUP BY item->'source_id', item->'pdf_page', item->'section' HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'duplicate citation identity or location' USING ERRCODE = '22023';
    END IF;
    RETURN (SELECT jsonb_agg(value ORDER BY value->>'id' COLLATE "C") FROM jsonb_array_elements(normalized));
END;
$$;

CREATE TABLE content_citation_revision (
    content_id canonical_id NOT NULL REFERENCES content_entry(id),
    revision bigint NOT NULL CHECK (revision >= 0),
    is_baseline boolean NOT NULL DEFAULT false,
    previous_revision bigint,
    old_citations jsonb,
    new_citations jsonb NOT NULL CHECK (jsonb_typeof(new_citations) = 'array'),
    reason text NOT NULL CHECK (reason ~ '\S'),
    operator_reference text NOT NULL CHECK (operator_reference ~ '\S'),
    operator_verification text NOT NULL DEFAULT 'unverified_local_reference'
        CHECK (operator_verification = 'unverified_local_reference'),
    database_actor text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CHECK ((is_baseline AND previous_revision IS NULL AND old_citations IS NULL)
        OR (NOT is_baseline AND revision > 0 AND previous_revision IS NOT NULL AND previous_revision = revision - 1
            AND old_citations IS NOT NULL AND jsonb_typeof(old_citations) = 'array'
            AND old_citations <> new_citations AND jsonb_array_length(new_citations) > 0)),
    PRIMARY KEY(content_id, revision)
);
CREATE UNIQUE INDEX one_citation_baseline_idx ON content_citation_revision(content_id) WHERE is_baseline;

-- Removing a draft citation must not free its canonical ID for another owner.
CREATE TABLE citation_identity (
    id canonical_id PRIMARY KEY,
    content_id canonical_id NOT NULL REFERENCES content_entry(id)
);
INSERT INTO citation_identity(id, content_id) SELECT id, content_id FROM content_source;
CREATE TRIGGER citation_identity_immutable BEFORE UPDATE OR DELETE ON citation_identity
    FOR EACH ROW EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER citation_identity_no_truncate BEFORE TRUNCATE ON citation_identity
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE FUNCTION reserve_citation_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.id IS DISTINCT FROM OLD.id OR NEW.content_id IS DISTINCT FROM OLD.content_id) THEN
        RAISE EXCEPTION 'citation identity and owner are immutable' USING ERRCODE = '55000';
    END IF;
    INSERT INTO citation_identity(id, content_id) VALUES (NEW.id, NEW.content_id) ON CONFLICT(id) DO NOTHING;
    IF NOT EXISTS (SELECT 1 FROM citation_identity WHERE id = NEW.id AND content_id = NEW.content_id) THEN
        RAISE EXCEPTION 'citation ID is reserved for another owner' USING ERRCODE = '23505';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER citation_identity_reserved BEFORE INSERT OR UPDATE ON content_source
    FOR EACH ROW EXECUTE FUNCTION reserve_citation_identity();

CREATE OR REPLACE FUNCTION assert_content_revision_chain(target_id canonical_id) RETURNS void LANGUAGE plpgsql AS $$
DECLARE expected bigint; total bigint; distinct_total bigint; highest bigint;
BEGIN
    SELECT draft_revision INTO expected FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT count(*), count(DISTINCT revision), COALESCE(max(revision),0) INTO total, distinct_total, highest FROM (
        SELECT revision FROM content_draft_revision WHERE content_id = target_id
        UNION ALL SELECT revision FROM curriculum_draft_revision WHERE content_id = target_id AND revision > 0
        UNION ALL SELECT revision FROM content_detail_revision WHERE content_id = target_id AND NOT is_baseline
        UNION ALL SELECT revision FROM content_citation_revision WHERE content_id = target_id AND NOT is_baseline
    ) events;
    IF total <> expected OR distinct_total <> expected OR highest <> expected THEN
        RAISE EXCEPTION 'draft revision chain is incomplete or duplicated' USING ERRCODE = '55000';
    END IF;
END;
$$;
CREATE FUNCTION guard_citation_revision_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE entry content_entry%ROWTYPE; citations jsonb;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id FOR UPDATE;
    IF NOT FOUND OR entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'citation revision requires a draft entry' USING ERRCODE = '55000';
    END IF;
    citations := content_citations_snapshot(NEW.content_id);
    IF NEW.is_baseline THEN
        IF NEW.revision <> entry.draft_revision OR NEW.new_citations IS DISTINCT FROM citations THEN
            RAISE EXCEPTION 'citation baseline mismatch' USING ERRCODE = '55000';
        END IF;
    ELSIF NEW.previous_revision IS DISTINCT FROM entry.draft_revision OR NEW.old_citations IS DISTINCT FROM citations
        OR NEW.new_citations IS DISTINCT FROM normalize_citation_set(NEW.content_id, NEW.new_citations) THEN
        RAISE EXCEPTION 'citation revision mismatch' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER citation_revision_insert BEFORE INSERT ON content_citation_revision
    FOR EACH ROW EXECUTE FUNCTION guard_citation_revision_insert();
CREATE TRIGGER citation_history_immutable BEFORE UPDATE OR DELETE ON content_citation_revision
    FOR EACH ROW EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER citation_history_no_truncate BEFORE TRUNCATE ON content_citation_revision
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE FUNCTION assert_citation_revision_applied(target_id canonical_id) RETURNS void LANGUAGE plpgsql AS $$
DECLARE current_revision bigint; latest content_citation_revision%ROWTYPE;
BEGIN
    SELECT draft_revision INTO current_revision FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT * INTO latest FROM content_citation_revision WHERE content_id = target_id ORDER BY revision DESC LIMIT 1;
    IF NOT FOUND OR current_revision < latest.revision OR content_citations_snapshot(target_id) IS DISTINCT FROM latest.new_citations THEN
        RAISE EXCEPTION 'citation changes require an applied revision' USING ERRCODE = '55000';
    END IF;
    PERFORM assert_content_revision_chain(target_id);
END;
$$;
CREATE FUNCTION check_citation_revision_applied() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN PERFORM assert_citation_revision_applied(NEW.content_id); RETURN NULL; END;
$$;
CREATE CONSTRAINT TRIGGER citation_revision_applied AFTER INSERT ON content_citation_revision
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_citation_revision_applied();
CREATE FUNCTION capture_citation_baseline() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO content_citation_revision(content_id, revision, is_baseline, new_citations, reason, operator_reference)
    SELECT id, draft_revision, true, content_citations_snapshot(id),
        'Observed local citation baseline; not approval.', 'local_database_baseline' FROM content_entry WHERE id = NEW.id;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER a_citation_baseline AFTER INSERT ON content_entry
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION capture_citation_baseline();
CREATE FUNCTION check_citation_set_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NOT EXISTS (SELECT 1 FROM content_citation_revision WHERE content_id = NEW.content_id) THEN RETURN NULL; END IF;
    IF TG_OP <> 'INSERT' THEN PERFORM assert_citation_revision_applied(OLD.content_id); END IF;
    IF TG_OP <> 'DELETE' THEN PERFORM assert_citation_revision_applied(NEW.content_id); END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER citation_set_consistent AFTER INSERT OR UPDATE OR DELETE ON content_source
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_citation_set_change();
CREATE TRIGGER citation_set_no_truncate BEFORE TRUNCATE ON content_source
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

-- Preserve step ownership while allowing a full citation-set replacement in a transaction.
DO $$ DECLARE reference_name text;
BEGIN
    SELECT conname INTO STRICT reference_name FROM pg_constraint WHERE conrelid = 'tul_step_source'::regclass
        AND confrelid = 'content_source'::regclass AND contype = 'f';
    EXECUTE format('ALTER TABLE tul_step_source RENAME CONSTRAINT %I TO tul_step_citation_owner_fk', reference_name);
END; $$;
ALTER TABLE tul_step_source ALTER CONSTRAINT tul_step_citation_owner_fk DEFERRABLE INITIALLY IMMEDIATE;

-- The exercise editor must check ownership before returning even if its caller
-- deferred the newly deferrable FK. Keep V5 immutable and adapt here.
CREATE OR REPLACE FUNCTION revise_tul_draft(target_id canonical_id, expected_revision bigint, replacement_details jsonb,
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
    SET CONSTRAINTS detail_revision_applied, catalog_details_consistent, tul_sequence_consistency,
        tul_step_consistency, tul_step_citation_owner_fk IMMEDIATE;
    RETURN expected_revision + 1;
END;
$$;

CREATE OR REPLACE FUNCTION guard_draft_entry_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW IS NOT DISTINCT FROM OLD THEN RETURN NEW; END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.content_type IS DISTINCT FROM OLD.content_type
        OR NEW.review_status IS DISTINCT FROM OLD.review_status OR NEW.draft_revision <> OLD.draft_revision + 1 THEN
        RAISE EXCEPTION 'content changes require a matching draft revision' USING ERRCODE = '55000';
    END IF;
    IF EXISTS (SELECT 1 FROM content_citation_revision r WHERE r.content_id = OLD.id AND NOT r.is_baseline
        AND r.revision = NEW.draft_revision AND r.previous_revision = OLD.draft_revision) THEN
        IF NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description THEN
            RAISE EXCEPTION 'citation edits cannot change generic text' USING ERRCODE = '55000';
        END IF;
    ELSIF OLD.content_type = 'gup' THEN
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
CREATE OR REPLACE FUNCTION assert_curriculum_revision_applied(target_id canonical_id) RETURNS void LANGUAGE plpgsql AS $$
DECLARE current_revision bigint; latest curriculum_draft_revision%ROWTYPE;
BEGIN
    SELECT draft_revision INTO current_revision FROM content_entry WHERE id = target_id;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT * INTO latest FROM curriculum_draft_revision WHERE content_id = target_id ORDER BY revision DESC LIMIT 1;
    IF NOT FOUND OR current_revision < latest.revision OR curriculum_requirements_snapshot(target_id) IS DISTINCT FROM latest.new_requirements THEN
        RAISE EXCEPTION 'curriculum changes require an applied revision' USING ERRCODE = '55000';
    END IF;
    PERFORM assert_content_revision_chain(target_id);
END;
$$;

CREATE FUNCTION revise_content_citations(target_id canonical_id, expected_revision bigint, replacement_citations jsonb,
    change_reason text, local_operator_reference text)
RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE entry content_entry%ROWTYPE; before_citations jsonb; after_citations jsonb;
BEGIN
    IF expected_revision IS NULL OR expected_revision < 0 OR NOT COALESCE(change_reason ~ '\S', false)
        OR NOT COALESCE(local_operator_reference ~ '\S', false) THEN
        RAISE EXCEPTION 'invalid citation edit parameters' USING ERRCODE = '22023';
    END IF;
    after_citations := normalize_citation_set(target_id, replacement_citations);
    -- Match import lock order and freeze registered page counts during citation checks.
    LOCK TABLE source_document IN SHARE MODE;
    LOCK TABLE content_entry IN ROW EXCLUSIVE MODE;
    LOCK TABLE content_source IN SHARE ROW EXCLUSIVE MODE;
    LOCK TABLE tul_step_source IN SHARE MODE;
    SELECT * INTO entry FROM content_entry WHERE id = target_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'citation owner not found' USING ERRCODE = 'P0002'; END IF;
    IF entry.review_status <> 'pending_human_review' THEN RAISE EXCEPTION 'citation owner is not a draft' USING ERRCODE = '55000'; END IF;
    IF entry.draft_revision <> expected_revision THEN RAISE EXCEPTION 'stale citation revision' USING ERRCODE = '40001'; END IF;
    PERFORM assert_citation_revision_applied(target_id);
    before_citations := content_citations_snapshot(target_id);
    IF before_citations = after_citations THEN RAISE EXCEPTION 'citation edit has no changes' USING ERRCODE = '22023'; END IF;
    SET CONSTRAINTS citation_revision_applied, citation_set_consistent, tul_step_citation_owner_fk DEFERRED;
    INSERT INTO content_citation_revision(content_id, revision, previous_revision, old_citations, new_citations, reason, operator_reference)
    VALUES (target_id, expected_revision + 1, expected_revision, before_citations, after_citations, change_reason, local_operator_reference);
    DELETE FROM content_source WHERE content_id = target_id;
    INSERT INTO content_source(id, content_id, source_id, source_sha256, pdf_page, printed_page, section, notes, review_status)
    SELECT id, content_id, source_id, source_sha256, pdf_page, printed_page, section, notes, review_status
        FROM jsonb_populate_recordset(NULL::content_source, after_citations);
    UPDATE content_entry SET draft_revision = expected_revision + 1 WHERE id = target_id;
    SET CONSTRAINTS citation_revision_applied, citation_set_consistent, tul_step_citation_owner_fk IMMEDIATE;
    RETURN expected_revision + 1;
END;
$$;

INSERT INTO content_citation_revision(content_id, revision, is_baseline, new_citations, reason, operator_reference)
SELECT id, draft_revision, true, content_citations_snapshot(id),
    'Observed citation baseline at V6 migration; not approval.', 'local_database_baseline' FROM content_entry;
REVOKE ALL ON TABLE content_citation_revision FROM PUBLIC;
REVOKE ALL ON TABLE citation_identity FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION revise_content_citations(canonical_id, bigint, jsonb, text, text) FROM PUBLIC;
