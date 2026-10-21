-- Isolated synthetic details only. Rollback restores values, counters and history.
BEGIN;
CREATE FUNCTION pg_temp.expect_detail_rejection(command text, expected_state text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = expected_state THEN RETURN; END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'expected detail rejection: %', expected_state;
END;
$$;
CREATE TEMP TABLE detail_test_payload AS SELECT
    '{"front_percent":null,"rear_percent":null,"front_rotation_deg":null,"rear_rotation_deg":null}'::jsonb AS unknown_position,
    '{"front_percent":47.25,"rear_percent":52.75,"front_rotation_deg":null,"rear_rotation_deg":25.5}'::jsonb AS observed_position,
    '{"translation":"Traducción sintética","aliases":["Alias nuevo","Otro"]}'::jsonb AS vocabulary_details;

SELECT revise_catalog_details('fixture_position', 1, 'position', observed_position, 'Synthetic observation.', 'Unverified test operator') FROM detail_test_payload;
SELECT revise_content_draft('fixture_position', 2, 'Mixed revision synthetic', 'Synthetic text after details.', 'Test only.', 'Unverified test operator');
SELECT revise_catalog_details('fixture_position', 3, 'position', unknown_position, 'Synthetic return to unknown.', 'Unverified test operator') FROM detail_test_payload;
SELECT revise_catalog_details('fixture_vocabulary', 0, 'vocabulary', vocabulary_details, 'Synthetic translation.', 'Unverified test operator') FROM detail_test_payload;
SELECT revise_content_draft('fixture_vocabulary', 1, 'Mixed vocabulary synthetic', 'Synthetic text after translation.', 'Test only.', 'Unverified test operator');
SELECT revise_catalog_details('fixture_vocabulary', 2, 'vocabulary', jsonb_set(vocabulary_details, '{aliases}', '[]'), 'Synthetic aliases cleared.', 'Unverified test operator') FROM detail_test_payload;

-- A newly inserted subtype can acquire a text revision before baseline capture.
INSERT INTO content_entry(id, content_type, name, description) VALUES ('fixture_detail_interop', 'vocabulary', 'Test', 'Test only');
INSERT INTO vocabulary(id, translation) VALUES ('fixture_detail_interop', 'Synthetic initial');
INSERT INTO content_source(id, content_id, source_id, source_sha256, pdf_page)
    VALUES ('citation_detail_interop', 'fixture_detail_interop', 'source_import_fixture', repeat('a', 64), 1);
SELECT revise_content_draft('fixture_detail_interop', 0, 'Synthetic text one', 'Test only', 'Test', 'Test');
SET CONSTRAINTS a_vocabulary_detail_baseline IMMEDIATE;
SELECT revise_catalog_details('fixture_detail_interop', 1, 'vocabulary', '{"translation":"Synthetic two","aliases":[]}', 'Test', 'Test');
SELECT revise_content_draft('fixture_detail_interop', 2, 'Synthetic text three', 'Test only', 'Test', 'Test');
SELECT revise_catalog_details('fixture_detail_interop', 3, 'vocabulary', '{"translation":"Synthetic four","aliases":[]}', 'Test', 'Test');

INSERT INTO content_entry(id, content_type, name, description) VALUES ('fixture_uncited_detail', 'position', 'Uncited synthetic', 'Test only');
INSERT INTO position(id) VALUES ('fixture_uncited_detail');
SET CONSTRAINTS ALL IMMEDIATE;

SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 1, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, '40001');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 0, 'vocabulary', vocabulary_details, 'Test', 'Test') FROM detail_test_payload$q$, '40001');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', unknown_position, 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', jsonb_set(vocabulary_details, '{aliases}', '[]'), 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('missing_entry', 0, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, 'P0002');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_tul', 0, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_tul', 0, 'tul', '{}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', NULL, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', -1, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position, ' ', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position, 'Test', ' ') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', NULL, 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"x":1}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position - 'rear_percent', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', jsonb_set(observed_position, '{rear_rotation_deg}', '"25"'), 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"front_percent":60,"rear_percent":50}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"front_percent":50,"rear_percent":null}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"front_percent":101,"rear_percent":-1}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"front_rotation_deg":360}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_position', 4, 'position', observed_position || '{"front_rotation_deg":-1}', 'Test', 'Test') FROM detail_test_payload$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', '{"translation":" ","aliases":[]}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', '{"translation":"Test","aliases":["A","A"]}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', '{"translation":"Test","aliases":null}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', '{"translation":"Test","aliases":[1]}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_vocabulary', 3, 'vocabulary', '{"translation":"Test","aliases":[" "]}', 'Test', 'Test')$q$, '22023');
SELECT pg_temp.expect_detail_rejection($q$UPDATE position SET rear_rotation_deg = 45 WHERE id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$UPDATE vocabulary SET translation = 'Unrecorded' WHERE id = 'fixture_vocabulary'$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$UPDATE content_entry SET draft_revision = 5 WHERE id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$UPDATE content_detail_revision SET reason = 'Changed' WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$DELETE FROM content_detail_revision WHERE content_id = 'fixture_position'$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$TRUNCATE content_detail_revision$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$TRUNCATE position CASCADE$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$TRUNCATE vocabulary CASCADE$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$SELECT revise_catalog_details('fixture_uncited_detail', 0, 'position', observed_position, 'Test', 'Test') FROM detail_test_payload$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$INSERT INTO content_detail_revision(content_id, content_type, revision, previous_revision,
    old_details, new_details, citation_snapshot, reason, operator_reference)
    SELECT 'fixture_position', 'position', 5, 4, p.unknown_position, p.observed_position, r.citation_snapshot, 'Test', 'Test'
    FROM detail_test_payload p CROSS JOIN content_detail_revision r WHERE r.content_id = 'fixture_position' AND r.revision = 2$q$, '55000');
SELECT pg_temp.expect_detail_rejection($q$INSERT INTO content_detail_revision(content_id, content_type, revision, previous_revision,
    old_details, new_details, citation_snapshot, reason, operator_reference)
    SELECT 'fixture_position', 'vocabulary', 5, 4, p.unknown_position, p.vocabulary_details, r.citation_snapshot, 'Test', 'Test'
    FROM detail_test_payload p CROSS JOIN content_detail_revision r WHERE r.content_id = 'fixture_position' AND r.revision = 2$q$, '55000');

DO $$ BEGIN
    IF catalog_details_snapshot('fixture_position', 'position') <> (SELECT unknown_position FROM detail_test_payload)
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 4
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_vocabulary') <> 3
        OR (SELECT translation FROM vocabulary WHERE id = 'fixture_vocabulary') <> U&'Traducci\00F3n sint\00E9tica'
        OR (SELECT cardinality(aliases) FROM vocabulary WHERE id = 'fixture_vocabulary') <> 0 THEN
        RAISE EXCEPTION 'detail data, nulls, UTF-8 or counter mismatch';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = 'fixture_position' AND revision = 2
        AND previous_revision = 1 AND old_details = (SELECT unknown_position FROM detail_test_payload)
        AND new_details = (SELECT observed_position FROM detail_test_payload)
        AND operator_verification = 'unverified_local_reference'
        AND citation_snapshot->0->>'source_sha256' = repeat('a', 64))
        OR NOT EXISTS (SELECT 1 FROM content_detail_revision WHERE content_id = 'fixture_detail_interop' AND is_baseline AND revision = 1) THEN
        RAISE EXCEPTION 'detail evidence or nonzero observed baseline missing';
    END IF;
    PERFORM assert_content_revision_chain('fixture_position');
    PERFORM assert_content_revision_chain('fixture_vocabulary');
    PERFORM assert_content_revision_chain('fixture_detail_interop');
END; $$;
ROLLBACK;
DO $$ BEGIN
    IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 1
        OR (SELECT draft_revision FROM content_entry WHERE id = 'fixture_vocabulary') <> 0
        OR EXISTS (SELECT 1 FROM content_detail_revision WHERE NOT is_baseline)
        OR EXISTS (SELECT 1 FROM content_entry WHERE id = 'fixture_detail_interop') THEN
        RAISE EXCEPTION 'detail transaction did not restore state/history';
    END IF;
END; $$;
