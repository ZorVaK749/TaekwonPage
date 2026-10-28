-- Synthetic fixtures only. Everything is rolled back, including successful inserts.
BEGIN;
CREATE FUNCTION pg_temp.expect_rejection(command text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE command;
    EXCEPTION WHEN integrity_constraint_violation OR raise_exception OR object_not_in_prerequisite_state THEN RETURN;
    END;
    RAISE EXCEPTION 'expected rejection: %', command;
END;
$$;
INSERT INTO content_entry (id, content_type, name, description) VALUES
    ('test_position', 'position', 'Synthetic', 'Test only'),
    ('test_tul', 'tul', 'Synthetic', 'Test only'),
    ('test_theory', 'theory', 'Synthetic', 'Test only'),
    ('gup_10', 'gup', 'Synthetic', 'Test only');
INSERT INTO position (id) VALUES ('test_position');
INSERT INTO theory_content (id) VALUES ('test_theory');
INSERT INTO gup (id, gup) VALUES ('gup_10', 10);
INSERT INTO tul (id, sequence_scope) VALUES ('test_tul', 'Synthetic partial list');
INSERT INTO tul_step VALUES ('test_tul', 1, 'test_position', 'Synthetic');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.expect_rejection($q$UPDATE position SET front_percent = 60, rear_percent = 50 WHERE id = 'test_position'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE position SET front_percent = 50 WHERE id = 'test_position'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE position SET front_rotation_deg = 360 WHERE id = 'test_position'$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO kick (id) VALUES ('test_theory')$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO gup_kick VALUES ('gup_10', 'test_theory')$q$);
SELECT pg_temp.expect_rejection($q$UPDATE content_entry SET id = 'changed_id' WHERE id = 'test_theory'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE content_entry SET review_status = 'approved' WHERE id = 'test_theory'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE tul SET sequence_scope = NULL WHERE id = 'test_tul'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE tul SET movement_count = 2, initial_position_id = 'test_position', sequence_complete = true WHERE id = 'test_tul'$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO tul_step VALUES ('test_tul', 1, 'test_position', 'Duplicate')$q$);
UPDATE tul SET movement_count = 1, initial_position_id = 'test_position', sequence_complete = true WHERE id = 'test_tul';
SELECT pg_temp.expect_rejection($q$DELETE FROM tul_step WHERE tul_id = 'test_tul'$q$);
SELECT pg_temp.expect_rejection($q$UPDATE source_document SET pdf_pages = 1 WHERE id = 'source_enciclopedia_taekwondo'$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO content_source (id, content_id, source_id, source_sha256, pdf_page)
    SELECT 'test_out_of_bounds', 'test_theory', id, sha256, pdf_pages + 1 FROM source_document LIMIT 1$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO content_source (id, content_id, source_id, source_sha256)
    SELECT 'test_no_location', 'test_theory', id, sha256 FROM source_document LIMIT 1$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO content_source (id, content_id, source_id, source_sha256, pdf_page)
    SELECT 'test_wrong_hash', 'test_theory', id, repeat('0', 64), 1 FROM source_document LIMIT 1$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO tul_step_source VALUES ('test_tul', 1, 'citation_dobok_web_p11')$q$);
DO $$
BEGIN
    IF (SELECT count(*) FROM content_entry WHERE id NOT IN ('test_position', 'test_tul', 'test_theory', 'gup_10')) <> 50
        OR (SELECT count(*) FROM content_source) <> 89 THEN
        RAISE EXCEPTION 'draft import counts mismatch';
    END IF;
    IF (SELECT translation FROM vocabulary WHERE id = 'dobok') <> U&'Uniforme de pr\00E1ctica' THEN
        RAISE EXCEPTION 'UTF-8 import corrupted';
    END IF;
END;
$$;
ROLLBACK;
