-- Synthetic exercise edits only; never completes or corrects a real exercise.
BEGIN;
CREATE FUNCTION pg_temp.expect_tul_rejection(command text, expected_state text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'expected exercise rejection: %', expected_state;
END;
$$;
CREATE TEMP TABLE tul_test_payload AS SELECT catalog_details_snapshot('fixture_tul', 'tul') AS original,
    '{"movement_count":null,"initial_position_id":null,"sequence_complete":false,"sequence_scope":"Synthetic partial list.","steps":[{"step_number":1,"position_id":"fixture_position","description":"Synthetic one","citation_ids":["citation_import_tul"]},{"step_number":3,"position_id":"fixture_position","description":"Synthetic three","citation_ids":["citation_import_tul"]}]}'::jsonb AS partial,
    '{"movement_count":2,"initial_position_id":"fixture_position","sequence_complete":true,"sequence_scope":null,"steps":[{"step_number":1,"position_id":"fixture_position","description":"Synthetic one","citation_ids":["citation_import_tul"]},{"step_number":2,"position_id":"fixture_position","description":"Synthetic two","citation_ids":["citation_import_tul"]}]}'::jsonb AS complete,
    '{"movement_count":null,"initial_position_id":null,"sequence_complete":false,"sequence_scope":null,"steps":[]}'::jsonb AS empty_partial;

SELECT revise_tul_draft('fixture_tul', 0, partial, 'Synthetic partial revision.', 'Unverified test operator') FROM tul_test_payload;
SELECT revise_content_draft('fixture_tul', 1, 'Mixed synthetic exercise', 'Test only.', 'Synthetic text.', 'Unverified test operator');
SELECT revise_tul_draft('fixture_tul', 2, complete, 'Synthetic complete fixture only.', 'Unverified test operator') FROM tul_test_payload;
SELECT revise_tul_draft('fixture_tul', 3, empty_partial, 'Synthetic unknown/empty draft.', 'Unverified test operator') FROM tul_test_payload;
SELECT revise_tul_draft('fixture_tul', 4, original, 'Synthetic forward restoration.', 'Unverified test operator') FROM tul_test_payload;
INSERT INTO content_entry(id, content_type, name, description) VALUES ('fixture_uncited_tul', 'tul', 'Uncited synthetic', 'Test only');
INSERT INTO tul(id) VALUES ('fixture_uncited_tul');
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 0, partial, 'Test', 'Test') FROM tul_test_payload$q$, '40001');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, original, 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('missing_tul', 0, partial, 'Test', 'Test') FROM tul_test_payload$q$, 'P0002');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_position', 2, partial, 'Test', 'Test') FROM tul_test_payload$q$, '55000');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', NULL, partial, 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', -1, partial, 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial, ' ', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial, 'Test', ' ') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, NULL, 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"rotation":90}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial - 'steps', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"steps":{}}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"movement_count":"2"}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"movement_count":0}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"movement_count":1.5}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"movement_count":2147483648}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"sequence_complete":true}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, complete || '{"initial_position_id":null}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, complete || '{"movement_count":3}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(complete, '{steps,1,step_number}', '3'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,1,step_number}', '1'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,step_number}', '0'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"sequence_scope":null}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"sequence_scope":" "}', 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,citation_ids}', '[]'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,citation_ids}', '["citation_import_tul","citation_import_tul"]'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,citation_ids}', '["Bad ID"]'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,description}', '" "'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,extra}', '90'), 'Test', 'Test') FROM tul_test_payload$q$, '22023');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"initial_position_id":"missing_position"}', 'Test', 'Test') FROM tul_test_payload$q$, '23503');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, partial || '{"initial_position_id":"fixture_theory"}', 'Test', 'Test') FROM tul_test_payload$q$, '23503');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,1,position_id}', '"missing_position"'), 'Test', 'Test') FROM tul_test_payload$q$, '23503');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,citation_ids}', '["citation_import_position"]'), 'Test', 'Test') FROM tul_test_payload$q$, '23503');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_tul', 5, jsonb_set(partial, '{steps,0,citation_ids}', '["missing_citation"]'), 'Test', 'Test') FROM tul_test_payload$q$, '23503');
SELECT pg_temp.expect_tul_rejection($q$UPDATE tul SET movement_count = 42 WHERE id = 'fixture_tul'$q$, '55000');
SELECT pg_temp.expect_tul_rejection($q$UPDATE tul_step SET description = 'Unrecorded' WHERE tul_id = 'fixture_tul'$q$, '55000');
SELECT pg_temp.expect_tul_rejection($q$DELETE FROM tul_step_source WHERE tul_id = 'fixture_tul'$q$, '55000');
SELECT pg_temp.expect_tul_rejection($q$TRUNCATE tul_step_source$q$, '55000');
SELECT pg_temp.expect_tul_rejection($q$SELECT revise_tul_draft('fixture_uncited_tul', 0, partial, 'Test', 'Test') FROM tul_test_payload$q$, '55000');

DO $$ BEGIN
    IF catalog_details_snapshot('fixture_tul', 'tul') <> (SELECT original FROM tul_test_payload)
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 5
        OR (SELECT movement_count FROM tul WHERE id = 'fixture_tul') IS NOT NULL
        OR (SELECT count(*) FROM content_detail_revision WHERE content_id = 'fixture_tul' AND NOT is_baseline) <> 4 THEN
        RAISE EXCEPTION 'exercise revision/state/rollback mismatch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = 'fixture_tul' AND revision = 1
        AND new_details = (SELECT partial FROM tul_test_payload) AND previous_revision = 0
        AND citation_snapshot->0->>'source_sha256' = repeat('a', 64)) THEN
        RAISE EXCEPTION 'exercise history lost partial state or evidence';
    END IF;
    IF EXISTS (SELECT 1 FROM tul WHERE id IN ('saju_jirugi', 'saju_makgi') AND (movement_count IS NOT NULL OR sequence_complete)) THEN
        RAISE EXCEPTION 'actual partial exercise was changed';
    END IF;
    PERFORM assert_content_revision_chain('fixture_tul');
END; $$;
ROLLBACK;
DO $$ BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 0
        OR (SELECT count(*) FROM tul_step WHERE tul_id = 'fixture_tul') <> 1
        OR EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = 'fixture_tul' AND NOT is_baseline) THEN
        RAISE EXCEPTION 'exercise transaction did not restore data/history';
    END IF;
END; $$;
