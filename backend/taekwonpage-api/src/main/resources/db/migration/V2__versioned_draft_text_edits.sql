-- Local editorial mechanism only: never approves or publishes content.
ALTER TABLE content_entry ADD COLUMN draft_revision bigint NOT NULL DEFAULT 0
    CHECK (draft_revision >= 0);

CREATE FUNCTION guard_initial_draft_revision() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.draft_revision <> 0 THEN
        RAISE EXCEPTION 'new content starts at draft revision zero' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER initial_draft_revision BEFORE INSERT ON content_entry
    FOR EACH ROW EXECUTE FUNCTION guard_initial_draft_revision();

CREATE TABLE content_draft_revision (
    content_id canonical_id NOT NULL REFERENCES content_entry (id),
    revision bigint NOT NULL CHECK (revision > 0),
    previous_revision bigint NOT NULL CHECK (previous_revision = revision - 1),
    old_name text NOT NULL CHECK (old_name ~ '\S'),
    old_description text NOT NULL CHECK (old_description ~ '\S'),
    new_name text NOT NULL CHECK (new_name ~ '\S'),
    new_description text NOT NULL CHECK (new_description ~ '\S'),
    reason text NOT NULL CHECK (reason ~ '\S'),
    operator_reference text NOT NULL CHECK (operator_reference ~ '\S'),
    operator_verification text NOT NULL DEFAULT 'unverified_local_reference'
        CHECK (operator_verification = 'unverified_local_reference'),
    database_actor text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    citation_snapshot jsonb NOT NULL CHECK (jsonb_typeof(citation_snapshot) = 'array'
        AND jsonb_array_length(citation_snapshot) > 0),
    CHECK (old_name IS DISTINCT FROM new_name OR old_description IS DISTINCT FROM new_description),
    PRIMARY KEY (content_id, revision)
);

CREATE FUNCTION guard_draft_revision_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    current_entry content_entry%ROWTYPE;
    citations jsonb;
BEGIN
    SELECT * INTO current_entry FROM content_entry WHERE id = NEW.content_id FOR UPDATE;
    IF NOT FOUND OR current_entry.content_type = 'gup'
        OR current_entry.review_status <> 'pending_human_review'
        OR current_entry.draft_revision <> NEW.previous_revision
        OR current_entry.name IS DISTINCT FROM NEW.old_name
        OR current_entry.description IS DISTINCT FROM NEW.old_description THEN
        RAISE EXCEPTION 'draft revision does not match current entry' USING ERRCODE = '55000';
    END IF;
    SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) INTO citations
        FROM content_source c WHERE c.content_id = NEW.content_id;
    IF NEW.citation_snapshot IS DISTINCT FROM citations THEN
        RAISE EXCEPTION 'draft citation snapshot mismatch' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER draft_revision_insert BEFORE INSERT ON content_draft_revision
    FOR EACH ROW EXECUTE FUNCTION guard_draft_revision_insert();

CREATE FUNCTION guard_draft_entry_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW IS NOT DISTINCT FROM OLD THEN RETURN NEW; END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.content_type IS DISTINCT FROM OLD.content_type
        OR NEW.review_status IS DISTINCT FROM OLD.review_status
        OR NEW.draft_revision <> OLD.draft_revision + 1
        OR NOT EXISTS (
            SELECT 1 FROM content_draft_revision r
            WHERE r.content_id = OLD.id AND r.revision = NEW.draft_revision
                AND r.previous_revision = OLD.draft_revision
                AND r.old_name = OLD.name AND r.old_description = OLD.description
                AND r.new_name = NEW.name AND r.new_description = NEW.description
        ) THEN
        RAISE EXCEPTION 'content changes require a matching draft revision' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER draft_entry_update BEFORE UPDATE ON content_entry
    FOR EACH ROW EXECUTE FUNCTION guard_draft_entry_update();

CREATE FUNCTION reject_draft_history_rewrite() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'draft history is append-only' USING ERRCODE = '55000';
END;
$$;
CREATE TRIGGER draft_history_immutable BEFORE UPDATE OR DELETE ON content_draft_revision
    FOR EACH ROW EXECUTE FUNCTION reject_draft_history_rewrite();
CREATE TRIGGER draft_history_no_truncate BEFORE TRUNCATE ON content_draft_revision
    FOR EACH STATEMENT EXECUTE FUNCTION reject_draft_history_rewrite();

CREATE FUNCTION check_draft_revision_applied() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    entry content_entry%ROWTYPE;
    latest content_draft_revision%ROWTYPE;
BEGIN
    SELECT * INTO entry FROM content_entry WHERE id = NEW.content_id;
    SELECT * INTO latest FROM content_draft_revision WHERE content_id = NEW.content_id ORDER BY revision DESC LIMIT 1;
    IF entry.draft_revision IS DISTINCT FROM latest.revision
        OR entry.name IS DISTINCT FROM latest.new_name
        OR entry.description IS DISTINCT FROM latest.new_description THEN
        RAISE EXCEPTION 'draft history has an unapplied revision' USING ERRCODE = '55000';
    END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER draft_revision_applied AFTER INSERT ON content_draft_revision
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_draft_revision_applied();

CREATE FUNCTION revise_content_draft(
    target_id canonical_id, expected_revision bigint,
    replacement_name text, replacement_description text,
    change_reason text, local_operator_reference text
) RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE
    current_entry content_entry%ROWTYPE;
    citations jsonb;
    next_revision bigint;
BEGIN
    IF expected_revision IS NULL OR expected_revision < 0
        OR NOT COALESCE(replacement_name ~ '\S', false)
        OR NOT COALESCE(replacement_description ~ '\S', false)
        OR NOT COALESCE(change_reason ~ '\S', false)
        OR NOT COALESCE(local_operator_reference ~ '\S', false) THEN
        RAISE EXCEPTION 'invalid draft edit parameters' USING ERRCODE = '22023';
    END IF;
    -- Acquire a table write lock before a row lock to serialize safely with imports.
    LOCK TABLE content_entry IN ROW EXCLUSIVE MODE;
    SELECT * INTO current_entry FROM content_entry WHERE id = target_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'draft entry not found' USING ERRCODE = 'P0002'; END IF;
    IF current_entry.content_type = 'gup' OR current_entry.review_status <> 'pending_human_review' THEN
        RAISE EXCEPTION 'entry is outside draft text edit scope' USING ERRCODE = '55000';
    END IF;
    IF current_entry.draft_revision <> expected_revision THEN
        RAISE EXCEPTION 'stale draft revision' USING ERRCODE = '40001';
    END IF;
    IF current_entry.name = replacement_name AND current_entry.description = replacement_description THEN
        RAISE EXCEPTION 'draft edit has no changes' USING ERRCODE = '22023';
    END IF;
    SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id) INTO citations
        FROM content_source c WHERE c.content_id = target_id;
    IF citations IS NULL THEN RAISE EXCEPTION 'draft edit requires citations' USING ERRCODE = '55000'; END IF;
    next_revision := expected_revision + 1;
    SET CONSTRAINTS draft_revision_applied DEFERRED;
    INSERT INTO content_draft_revision(content_id, revision, previous_revision,
        old_name, old_description, new_name, new_description, reason, operator_reference, citation_snapshot)
    VALUES (target_id, next_revision, expected_revision, current_entry.name, current_entry.description,
        replacement_name, replacement_description, change_reason, local_operator_reference, citations);
    UPDATE content_entry SET name = replacement_name, description = replacement_description,
        draft_revision = next_revision WHERE id = target_id;
    SET CONSTRAINTS draft_revision_applied IMMEDIATE;
    RETURN next_revision;
END;
$$;

-- No general-purpose application grants before identity/authorization is designed.
REVOKE ALL ON TABLE content_draft_revision FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION revise_content_draft(canonical_id, bigint, text, text, text, text) FROM PUBLIC;
