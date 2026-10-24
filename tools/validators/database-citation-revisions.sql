-- Synthetic documentary corrections only. Data and all revision history roll back.
BEGIN;
CREATE FUNCTION pg_temp.expect_citation_rejection(command text, expected_state text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'expected citation rejection: %', expected_state;
END;
$$;
CREATE TEMP TABLE citation_test_payload AS SELECT content_citations_snapshot('fixture_position') AS original_position,
    content_citations_snapshot('gup_10') AS original_gup, content_citations_snapshot('fixture_tul') AS original_tul;
ALTER TABLE citation_test_payload ADD COLUMN two_position jsonb;
UPDATE citation_test_payload SET two_position = original_position || jsonb_build_array((original_position->0)
    || '{"id":"citation_position_second","pdf_page":2,"printed_page":"Observed folio X"}');
SELECT revise_content_citations('fixture_position', 2, two_position, 'Synthetic extra evidence.', 'Unverified test operator') FROM citation_test_payload;
-- Swap two occupied locations: replacement must not hit transient unique conflicts.
SELECT revise_content_citations('fixture_position', 3,
    jsonb_set(jsonb_set(two_position, '{0,pdf_page}', '2'), '{1,pdf_page}', '1'),
    'Synthetic location swap.', 'Unverified test operator') FROM citation_test_payload;
SELECT revise_content_draft('fixture_position', 4, 'Evidence-aware synthetic text', 'Test only.', 'Synthetic after citations.', 'Unverified test operator');
SELECT revise_content_citations('gup_10', 1, jsonb_set(original_gup, '{0,notes}', '"Synthetic corrected note"'),
    'Synthetic curriculum evidence.', 'Unverified test operator') FROM citation_test_payload;
SELECT revise_curriculum_draft('gup_10', 2,
    jsonb_set(curriculum_requirements_snapshot('gup_10'), '{position_ids}', '["fixture_position"]'), 'Synthetic after evidence.', 'Unverified test operator');
SELECT revise_content_citations('fixture_tul', 1, jsonb_set(original_tul, '{0,pdf_page}', '2'),
    'Synthetic exercise evidence.', 'Unverified test operator') FROM citation_test_payload;
SELECT revise_content_draft('fixture_tul', 2, 'Evidence-aware synthetic exercise', 'Test only.', 'Synthetic after evidence.', 'Unverified test operator');

-- First evidence for a new owner; the observed baseline is not human review.
INSERT INTO content_entry(id, content_type, name, description) VALUES ('fixture_evidence_init', 'theory', 'Synthetic initial', 'Test only');
INSERT INTO theory_content(id) VALUES ('fixture_evidence_init');
SET CONSTRAINTS a_citation_baseline IMMEDIATE;
SELECT revise_content_citations('fixture_evidence_init', 0,
    jsonb_build_array((original_position->0) || '{"id":"citation_initial_evidence","content_id":"fixture_evidence_init","pdf_page":3}'),
    'Synthetic first evidence.', 'Unverified test operator') FROM citation_test_payload;
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 2, original_position, 'Test', 'Test') FROM citation_test_payload$q$, '40001');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, content_citations_snapshot('fixture_position'), 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('missing_owner', 0, jsonb_set(original_position, '{0,content_id}', '"missing_owner"'), 'Test', 'Test') FROM citation_test_payload$q$, 'P0002');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', NULL, original_position, 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', -1, original_position, 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, original_position, ' ', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, original_position, 'Test', ' ') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, NULL, 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, '[]', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, '{}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, original_position || original_position, 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, original_position || jsonb_build_array((original_position->0) || '{"id":"citation_duplicate_location"}'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,content_id}', '"another_owner"'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,id}', '"Bad ID"'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,review_status}', '"approved"'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,file_reference}', '"not_allowed.pdf"'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', '0'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', '1.5'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', '"2"'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', '2147483648'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', 'null'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,printed_page}', '" "'), 'Test', 'Test') FROM citation_test_payload$q$, '22023');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,source_id}', '"missing_source"'), 'Test', 'Test') FROM citation_test_payload$q$, '23503');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,source_sha256}', to_jsonb(repeat('0',64))), 'Test', 'Test') FROM citation_test_payload$q$, '23503');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,pdf_page}', '11'), 'Test', 'Test') FROM citation_test_payload$q$, 'P0001');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_position', 5, jsonb_set(original_position, '{0,id}', '"citation_import_vocabulary"'), 'Test', 'Test') FROM citation_test_payload$q$, '23505');
-- Removing an ID still cited by an exercise must fail late and restore all rows.
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_tul', 3, jsonb_set(original_tul, '{0,id}', '"citation_removed_step_reference"'), 'Test', 'Test') FROM citation_test_payload$q$, '23503');
SELECT pg_temp.expect_citation_rejection($q$UPDATE content_source SET notes = 'Unrecorded' WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$DELETE FROM content_source WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$TRUNCATE content_source CASCADE$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$UPDATE content_source SET content_id = 'fixture_vocabulary' WHERE id = 'citation_import_position'$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$UPDATE content_citation_revision SET reason = 'Rewritten' WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$DELETE FROM content_citation_revision WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$TRUNCATE content_citation_revision$q$, '55000');
SELECT pg_temp.expect_citation_rejection($q$DELETE FROM citation_identity WHERE id = 'citation_import_position'$q$, '55000');
SET CONSTRAINTS tul_step_citation_owner_fk DEFERRED;
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_tul_draft('fixture_tul', 3,
    jsonb_set(catalog_details_snapshot('fixture_tul','tul'), '{steps,0,citation_ids}', '["citation_import_position"]'),
    'Test', 'Test')$q$, '23503');
SET CONSTRAINTS tul_step_citation_owner_fk IMMEDIATE;

-- Removing an unreferenced citation does not release its canonical identity.
SELECT revise_content_citations('fixture_position', 5,
    jsonb_build_array(content_citations_snapshot('fixture_position')->0), 'Synthetic unused citation removed.', 'Unverified test operator');
SELECT pg_temp.expect_citation_rejection($q$SELECT revise_content_citations('fixture_vocabulary', 0,
    jsonb_build_array((original_position->0) || '{"id":"citation_position_second","content_id":"fixture_vocabulary"}'),
    'Test', 'Test') FROM citation_test_payload$q$, '23505');
SELECT revise_content_citations('fixture_position', 6,
    jsonb_set(jsonb_set(content_citations_snapshot('fixture_position'), '{0,pdf_page}', 'null'),
        '{0,section}', '"Sección sintética"'), 'Synthetic section-only locator.', 'Unverified test operator');

DO $$ BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 7
        OR (SELECT draft_revision FROM content_entry WHERE id = 'gup_10') <> 3
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 3
        OR (SELECT count(*) FROM content_source WHERE content_id = 'fixture_position') <> 1
        OR (SELECT pdf_page FROM content_source WHERE id = 'citation_import_position') IS NOT NULL
        OR (SELECT section FROM content_source WHERE id = 'citation_import_position') <> U&'Secci\00F3n sint\00E9tica'
        OR (SELECT count(*) FROM tul_step_source WHERE tul_id = 'fixture_tul') <> 2
        OR (SELECT pdf_page FROM content_source WHERE id = 'citation_import_tul') <> 2 THEN
        RAISE EXCEPTION 'citation revision, swap or rollback mismatch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM content_citation_revision WHERE content_id = 'fixture_position' AND revision = 3
        AND previous_revision = 2 AND old_citations = (SELECT original_position FROM citation_test_payload)
        AND operator_verification = 'unverified_local_reference' AND database_actor = session_user) THEN
        RAISE EXCEPTION 'citation history lost original evidence or operator context';
    END IF;
    PERFORM assert_content_revision_chain('fixture_position');
    PERFORM assert_catalog_details_applied('fixture_position');
    PERFORM assert_curriculum_revision_applied('gup_10');
    PERFORM assert_catalog_details_applied('fixture_tul');
    PERFORM assert_citation_revision_applied('fixture_tul');
END; $$;
ROLLBACK;
DO $$ BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 2
        OR (SELECT draft_revision FROM content_entry WHERE id = 'gup_10') <> 1
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 1
        OR EXISTS (SELECT 1 FROM content_citation_revision WHERE NOT is_baseline)
        OR EXISTS (SELECT 1 FROM citation_identity WHERE id = 'citation_position_second') THEN
        RAISE EXCEPTION 'citation transaction did not restore evidence, reservations or history';
    END IF;
END; $$;
