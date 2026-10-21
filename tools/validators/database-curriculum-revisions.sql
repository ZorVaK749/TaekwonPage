-- Only isolated synthetic curricula are edited. Everything here is rolled back.
BEGIN;
CREATE FUNCTION pg_temp.expect_curriculum_rejection(command text, expected_state text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'expected curriculum rejection: %', expected_state;
END;
$$;
CREATE TEMP TABLE curriculum_test_payload AS
SELECT curriculum_requirements_snapshot('gup_10') AS original,
    '{"position_ids":[],"theory_ids":[],"vocabulary_ids":[],"body_tool_ids":["fixture_body_tool"],"kick_ids":[],"tul_ids":[],"combat_ids":[]}'::jsonb AS reduced;

INSERT INTO content_entry(id, content_type, name, description) VALUES
    ('gup_9', 'gup', 'Synthetic nine', 'Test only'),
    ('gup_8', 'gup', 'Synthetic uncited', 'Test only'),
    ('fixture_kick_extra', 'kick', 'Synthetic kick', 'Test only'),
    ('fixture_missing_subtype', 'kick', 'Malformed synthetic row', 'Intentionally missing subtype to test late FK rollback');
INSERT INTO gup(id, gup) VALUES ('gup_9', 9), ('gup_8', 8);
INSERT INTO gup_tool VALUES ('gup_9', 'fixture_body_tool');
INSERT INTO gup_position VALUES ('gup_8', 'fixture_position');
INSERT INTO kick(id) VALUES ('fixture_kick_extra');
SET CONSTRAINTS curriculum_baseline_capture IMMEDIATE;

SELECT revise_curriculum_draft('gup_10', 0, reduced, 'Synthetic reduction.', 'Unverified test operator') FROM curriculum_test_payload;
DO $$ BEGIN
    IF curriculum_requirements_snapshot('gup_10') <> (SELECT reduced FROM curriculum_test_payload)
        OR curriculum_requirements_snapshot('gup_9') <> (SELECT reduced FROM curriculum_test_payload) THEN
        RAISE EXCEPTION 'curriculum update or isolation mismatch';
    END IF;
END; $$;
-- Restore all seven groups as a second forward revision, not a destructive undo.
SELECT revise_curriculum_draft('gup_10', 1, original, 'Synthetic restoration.', 'Unverified test operator') FROM curriculum_test_payload;
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 0, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, '40001');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, original, 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_7', 0, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, 'P0002');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('fixture_position', 0, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', NULL, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', -1, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, reduced, ' ', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, reduced, 'Test', ' ') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, original - 'combat_ids', 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, original || '{"unexpected":[]}', 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '"not an array"'), 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '[1]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '["Bad ID"]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '["fixture_position","fixture_position"]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, (SELECT jsonb_object_agg(field_name, '[]'::jsonb) FROM curriculum_requirement_groups()), 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '["fixture_theory"]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '23503');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{position_ids}', '["missing_position"]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '23503');
-- This passes the base-type check but fails the actual subtype FK after writes start.
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, jsonb_set(original, '{kick_ids}', '["fixture_missing_subtype"]'), 'Test', 'Test') FROM curriculum_test_payload$q$, '23503');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_8', 0, reduced, 'Test', 'Test') FROM curriculum_test_payload$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$DELETE FROM gup_position WHERE gup_id = 'gup_10'$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$INSERT INTO gup_kick VALUES ('gup_10', 'fixture_kick_extra')$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$UPDATE gup_position SET gup_id = 'gup_9' WHERE gup_id = 'gup_10'$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$TRUNCATE gup_position$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$UPDATE curriculum_draft_revision SET reason = 'Changed' WHERE content_id = 'gup_10'$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$DELETE FROM curriculum_draft_revision WHERE content_id = 'gup_10'$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$TRUNCATE curriculum_draft_revision$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$UPDATE content_entry SET draft_revision = 3 WHERE id = 'gup_10'$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$INSERT INTO curriculum_draft_revision(content_id, revision, previous_revision, old_requirements, new_requirements, citation_snapshot, reason, operator_reference)
    SELECT 'gup_10', 3, 2, p.original, p.reduced, r.citation_snapshot, 'Test', 'Test'
    FROM curriculum_test_payload p CROSS JOIN curriculum_draft_revision r WHERE r.content_id = 'gup_10' AND r.revision = 2$q$, '55000');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, NULL, 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_curriculum_rejection($q$SELECT revise_curriculum_draft('gup_10', 2, '[]', 'Test', 'Test')$q$, '22023');

DO $$ BEGIN
    IF normalize_curriculum_requirements(jsonb_set((SELECT original FROM curriculum_test_payload),
        '{position_ids}', '["fixture_z","fixture_a"]'))->'position_ids' <> '["fixture_a","fixture_z"]'::jsonb THEN
        RAISE EXCEPTION 'requirement set normalization is not deterministic';
    END IF;
    IF (SELECT draft_revision FROM content_entry WHERE id = 'gup_10') <> 2
        OR (SELECT review_status FROM content_entry WHERE id = 'gup_10') <> 'pending_human_review'
        OR (SELECT count(*) FROM curriculum_draft_revision WHERE content_id = 'gup_10') <> 3
        OR curriculum_requirements_snapshot('gup_10') <> (SELECT original FROM curriculum_test_payload)
        OR curriculum_requirements_snapshot('gup_9') <> (SELECT reduced FROM curriculum_test_payload) THEN
        RAISE EXCEPTION 'curriculum revision, rollback or isolation mismatch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM curriculum_draft_revision r WHERE r.content_id = 'gup_10' AND r.revision = 1
        AND r.previous_revision = 0 AND r.old_requirements = (SELECT original FROM curriculum_test_payload)
        AND r.new_requirements = (SELECT reduced FROM curriculum_test_payload)
        AND r.operator_verification = 'unverified_local_reference' AND r.database_actor = session_user
        AND r.citation_snapshot->0->>'source_sha256' = repeat('a', 64)) THEN
        RAISE EXCEPTION 'curriculum history/evidence mismatch';
    END IF;
END; $$;
ROLLBACK;
DO $$ BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'gup_10') <> 0
        OR (SELECT count(*) FROM curriculum_draft_revision WHERE content_id = 'gup_10') <> 1
        OR EXISTS (SELECT 1 FROM gup WHERE id IN ('gup_8', 'gup_9')) THEN
        RAISE EXCEPTION 'curriculum transaction rollback did not restore baseline';
    END IF;
END; $$;
