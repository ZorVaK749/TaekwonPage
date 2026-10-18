-- Synthetic fixture edits only; both data changes and journal rows are rolled back.
BEGIN;
CREATE FUNCTION pg_temp.expect_edit_rejection(command text, expected_state text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'expected edit rejection: %', expected_state;
END;
$$;

SELECT revise_content_draft('fixture_position', 0, 'Revised synthetic', 'Revision one description.', 'Synthetic correction.', 'Unverified test operator');
SELECT revise_content_draft('fixture_position', 1, 'Revised synthetic', 'Revision two description.', 'Synthetic follow-up.', 'Unverified test operator');
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 0, 'Stale', 'Stale edit', 'Test', 'Test')$q$, '40001');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 2, 'Revised synthetic', 'Revision two description.', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', NULL, 'Changed', 'Changed', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', -1, 'Changed', 'Changed', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 2, ' ', 'Changed', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 2, 'Changed', ' ', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 2, 'Changed', 'Changed', ' ', 'Test')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_position', 2, 'Changed', 'Changed', 'Test', ' ')$q$, '22023');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('missing_entry', 0, 'Changed', 'Changed', 'Test', 'Test')$q$, 'P0002');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('gup_10', 0, 'Changed', 'Changed', 'Test', 'Test')$q$, '55000');
INSERT INTO content_entry(id, content_type, name, description) VALUES ('fixture_uncited', 'theory', 'Uncited synthetic', 'Test only');
SELECT pg_temp.expect_edit_rejection($q$SELECT revise_content_draft('fixture_uncited', 0, 'Changed', 'Changed', 'Test', 'Test')$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$UPDATE content_entry SET name = 'Unrecorded' WHERE id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$UPDATE content_entry SET draft_revision = 3 WHERE id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$UPDATE content_draft_revision SET reason = 'Rewritten' WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$DELETE FROM content_draft_revision WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$TRUNCATE content_draft_revision$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$INSERT INTO content_entry(id, content_type, name, description, draft_revision)
    VALUES ('fixture_nonzero', 'theory', 'Test', 'Test only', 5)$q$, '55000');
SELECT pg_temp.expect_edit_rejection($q$INSERT INTO content_draft_revision(content_id, revision, previous_revision,
    old_name, old_description, new_name, new_description, reason, operator_reference, citation_snapshot)
    SELECT e.id, 3, 2, e.name, e.description, 'Unapplied', 'Test', 'Test', 'Test', r.citation_snapshot
    FROM content_entry e JOIN content_draft_revision r ON r.content_id = e.id AND r.revision = 2
    WHERE e.id = 'fixture_position'$q$, '55000');

DO $$
BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 2
        OR (SELECT review_status FROM content_entry WHERE id = 'fixture_position') <> 'pending_human_review'
        OR (SELECT count(*) FROM content_draft_revision WHERE content_id = 'fixture_position') <> 2 THEN
        RAISE EXCEPTION 'draft revision/state/history mismatch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM content_draft_revision WHERE content_id = 'fixture_position' AND revision = 1
        AND previous_revision = 0 AND old_name = 'Synthetic position' AND new_name = 'Revised synthetic'
        AND operator_verification = 'unverified_local_reference' AND database_actor = session_user
        AND citation_snapshot->0->>'source_sha256' = repeat('a', 64)) THEN
        RAISE EXCEPTION 'draft history did not preserve old/new fields or evidence';
    END IF;
END;
$$;
ROLLBACK;

-- Prove the caller's transaction rollback also undid the journal, not only text.
DO $$
BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 0
        OR (SELECT name FROM content_entry WHERE id = 'fixture_position') <> 'Synthetic position'
        OR EXISTS (SELECT 1 FROM content_draft_revision) THEN
        RAISE EXCEPTION 'draft edit rollback did not restore state/history';
    END IF;
END;
$$;
