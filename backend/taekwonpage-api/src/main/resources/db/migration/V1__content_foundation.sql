-- Draft persistence only. No approval/publication workflow or martial seed.
CREATE DOMAIN canonical_id AS text
    CHECK (VALUE ~ '^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

CREATE TABLE source_document (
    id canonical_id PRIMARY KEY,
    sha256 text NOT NULL UNIQUE CHECK (sha256 ~ '^[a-f0-9]{64}$'),
    size_bytes bigint NOT NULL CHECK (size_bytes > 0),
    pdf_pages integer NOT NULL CHECK (pdf_pages > 0),
    title text,
    organization text,
    author text,
    edition text,
    language text,
    file_reference text NOT NULL UNIQUE,
    metadata_evidence text,
    notes text,
    review_status text NOT NULL DEFAULT 'pending_human_review'
        CHECK (review_status = 'pending_human_review'),
    redistribution_status text NOT NULL DEFAULT 'unknown'
        CHECK (redistribution_status = 'unknown'),
    UNIQUE (id, sha256)
);

-- Shared identity prevents cross-catalog duplicate IDs. Composite FKs preserve types.
CREATE TABLE content_entry (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL CHECK (content_type IN
        ('position', 'theory', 'vocabulary', 'body_tool', 'kick', 'combat', 'tul', 'gup')),
    name text NOT NULL CHECK (name ~ '\S'),
    description text NOT NULL CHECK (description ~ '\S'),
    review_status text NOT NULL DEFAULT 'pending_human_review'
        CHECK (review_status = 'pending_human_review'),
    UNIQUE (id, content_type)
);

CREATE TABLE position (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'position' CHECK (content_type = 'position'),
    front_percent numeric CHECK (front_percent BETWEEN 0 AND 100),
    rear_percent numeric CHECK (rear_percent BETWEEN 0 AND 100),
    front_rotation_deg numeric CHECK (front_rotation_deg >= 0 AND front_rotation_deg < 360),
    rear_rotation_deg numeric CHECK (rear_rotation_deg >= 0 AND rear_rotation_deg < 360),
    CHECK ((front_percent IS NULL AND rear_percent IS NULL) OR
        (front_percent IS NOT NULL AND rear_percent IS NOT NULL AND front_percent + rear_percent = 100)),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);

CREATE TABLE theory_content (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'theory' CHECK (content_type = 'theory'),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE vocabulary (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'vocabulary' CHECK (content_type = 'vocabulary'),
    translation text NOT NULL CHECK (translation ~ '\S'),
    aliases text[] NOT NULL DEFAULT '{}',
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE body_tool (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'body_tool' CHECK (content_type = 'body_tool'),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE kick (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'kick' CHECK (content_type = 'kick'),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE combat_type (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'combat' CHECK (content_type = 'combat'),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE tul (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'tul' CHECK (content_type = 'tul'),
    movement_count integer CHECK (movement_count > 0),
    initial_position_id canonical_id REFERENCES position (id),
    sequence_complete boolean NOT NULL DEFAULT false,
    sequence_scope text CHECK (sequence_scope ~ '\S'),
    CHECK (NOT sequence_complete OR (movement_count IS NOT NULL AND initial_position_id IS NOT NULL)),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE tul_step (
    tul_id canonical_id NOT NULL REFERENCES tul (id),
    step_number integer NOT NULL CHECK (step_number > 0),
    position_id canonical_id NOT NULL REFERENCES position (id),
    description text NOT NULL CHECK (description ~ '\S'),
    PRIMARY KEY (tul_id, step_number)
);

CREATE TABLE gup (
    id canonical_id PRIMARY KEY,
    content_type text NOT NULL DEFAULT 'gup' CHECK (content_type = 'gup'),
    gup integer NOT NULL UNIQUE CHECK (gup BETWEEN 1 AND 10),
    CHECK (id = 'gup_' || gup::text),
    FOREIGN KEY (id, content_type) REFERENCES content_entry (id, content_type)
);
CREATE TABLE gup_position (
    gup_id canonical_id REFERENCES gup (id), position_id canonical_id REFERENCES position (id),
    PRIMARY KEY (gup_id, position_id)
);
CREATE TABLE gup_theory (
    gup_id canonical_id REFERENCES gup (id), theory_id canonical_id REFERENCES theory_content (id),
    PRIMARY KEY (gup_id, theory_id)
);
CREATE TABLE gup_vocabulary (
    gup_id canonical_id REFERENCES gup (id), vocabulary_id canonical_id REFERENCES vocabulary (id),
    PRIMARY KEY (gup_id, vocabulary_id)
);
CREATE TABLE gup_tool (
    gup_id canonical_id REFERENCES gup (id), tool_id canonical_id REFERENCES body_tool (id),
    PRIMARY KEY (gup_id, tool_id)
);
CREATE TABLE gup_kick (
    gup_id canonical_id REFERENCES gup (id), kick_id canonical_id REFERENCES kick (id),
    PRIMARY KEY (gup_id, kick_id)
);
CREATE TABLE gup_tul (
    gup_id canonical_id REFERENCES gup (id), tul_id canonical_id REFERENCES tul (id),
    PRIMARY KEY (gup_id, tul_id)
);
CREATE TABLE gup_combat (
    gup_id canonical_id REFERENCES gup (id), combat_id canonical_id REFERENCES combat_type (id),
    PRIMARY KEY (gup_id, combat_id)
);

CREATE TABLE content_source (
    id canonical_id PRIMARY KEY,
    content_id canonical_id NOT NULL REFERENCES content_entry (id),
    source_id canonical_id NOT NULL,
    source_sha256 text NOT NULL,
    pdf_page integer CHECK (pdf_page > 0),
    printed_page text,
    section text,
    notes text,
    review_status text NOT NULL DEFAULT 'pending_human_review'
        CHECK (review_status = 'pending_human_review'),
    CHECK (pdf_page IS NOT NULL OR COALESCE(section ~ '\S', false)),
    FOREIGN KEY (source_id, source_sha256) REFERENCES source_document (id, sha256),
    UNIQUE NULLS NOT DISTINCT (content_id, source_id, pdf_page, section),
    UNIQUE (id, content_id)
);
CREATE TABLE tul_step_source (
    tul_id canonical_id NOT NULL,
    step_number integer NOT NULL,
    citation_id canonical_id NOT NULL,
    PRIMARY KEY (tul_id, step_number, citation_id),
    FOREIGN KEY (tul_id, step_number) REFERENCES tul_step (tul_id, step_number),
    FOREIGN KEY (citation_id, tul_id) REFERENCES content_source (id, content_id)
);

CREATE INDEX content_source_source_idx ON content_source (source_id);
CREATE INDEX tul_initial_position_idx ON tul (initial_position_id);
CREATE INDEX tul_step_position_idx ON tul_step (position_id);
CREATE INDEX gup_position_reverse_idx ON gup_position (position_id);
CREATE INDEX gup_theory_reverse_idx ON gup_theory (theory_id);
CREATE INDEX gup_vocabulary_reverse_idx ON gup_vocabulary (vocabulary_id);
CREATE INDEX gup_tool_reverse_idx ON gup_tool (tool_id);
CREATE INDEX gup_kick_reverse_idx ON gup_kick (kick_id);
CREATE INDEX gup_tul_reverse_idx ON gup_tul (tul_id);
CREATE INDEX gup_combat_reverse_idx ON gup_combat (combat_id);

CREATE FUNCTION check_citation_page() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.pdf_page > (SELECT pdf_pages FROM source_document WHERE id = NEW.source_id) THEN
        RAISE EXCEPTION 'citation page exceeds registered source';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER citation_page_bounds BEFORE INSERT OR UPDATE ON content_source
    FOR EACH ROW EXECUTE FUNCTION check_citation_page();

CREATE FUNCTION check_source_page_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM content_source WHERE source_id = NEW.id AND pdf_page > NEW.pdf_pages) THEN
        RAISE EXCEPTION 'source page count invalidates existing citations';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER source_page_bounds BEFORE UPDATE ON source_document
    FOR EACH ROW EXECUTE FUNCTION check_source_page_update();

-- Deferred so a complete sequence and its steps can be inserted in one transaction.
CREATE FUNCTION check_tul_sequence() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    target_id canonical_id;
    t tul%ROWTYPE;
    n bigint;
    highest integer;
BEGIN
    IF TG_TABLE_NAME = 'tul' THEN
        target_id := COALESCE(NEW.id, OLD.id);
    ELSE
        target_id := COALESCE(NEW.tul_id, OLD.tul_id);
    END IF;
    SELECT * INTO t FROM tul WHERE id = target_id;
    IF NOT FOUND THEN RETURN NULL; END IF;
    SELECT count(*), max(step_number) INTO n, highest FROM tul_step WHERE tul_id = target_id;
    IF t.movement_count IS NOT NULL AND highest > t.movement_count THEN
        RAISE EXCEPTION 'step exceeds movement_count';
    END IF;
    IF t.sequence_complete AND (n <> t.movement_count OR highest <> t.movement_count) THEN
        RAISE EXCEPTION 'complete sequence requires contiguous steps';
    END IF;
    IF NOT t.sequence_complete AND n > 0 AND t.sequence_scope IS NULL THEN
        RAISE EXCEPTION 'partial steps require sequence_scope';
    END IF;
    RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER tul_sequence_consistency AFTER INSERT OR UPDATE ON tul
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_tul_sequence();
CREATE CONSTRAINT TRIGGER tul_step_consistency AFTER INSERT OR UPDATE OR DELETE ON tul_step
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_tul_sequence();

-- Identity keys are immutable, including the parent of an existing step.
CREATE FUNCTION reject_identity_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id THEN RAISE EXCEPTION 'canonical IDs are immutable'; END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER content_id_immutable BEFORE UPDATE ON content_entry
    FOR EACH ROW EXECUTE FUNCTION reject_identity_change();
CREATE TRIGGER source_id_immutable BEFORE UPDATE ON source_document
    FOR EACH ROW EXECUTE FUNCTION reject_identity_change();
CREATE FUNCTION reject_step_identity_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (NEW.tul_id, NEW.step_number) IS DISTINCT FROM (OLD.tul_id, OLD.step_number) THEN
        RAISE EXCEPTION 'step identity is immutable';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER step_id_immutable BEFORE UPDATE ON tul_step
    FOR EACH ROW EXECUTE FUNCTION reject_step_identity_change();
