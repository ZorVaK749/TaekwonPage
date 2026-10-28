-- This database contains actual drafts + isolated synthetic importer fixtures.
DO $$
DECLARE
    linked bigint;
BEGIN
    IF (SELECT count(*) FROM content_entry) <> 72
        OR (SELECT count(*) FROM content_source) <> 120
        OR (SELECT count(*) FROM source_document) <> 5
        OR (SELECT count(*) FROM gup) <> 1 THEN
        RAISE EXCEPTION 'import/reload counts mismatch';
    END IF;
    IF EXISTS (SELECT 1 FROM source_document WHERE id = 'source_rollback_probe')
        OR EXISTS (SELECT 1 FROM content_entry WHERE id = 'fixture_position_extra')
        OR (SELECT count(*) FROM tul_step WHERE tul_id = 'fixture_tul') <> 1 THEN
        RAISE EXCEPTION 'partial import was not rolled back';
    END IF;
    SELECT sum(n) INTO linked FROM (
        SELECT count(*) n FROM gup_position WHERE gup_id = 'gup_10' AND position_id = 'fixture_position'
        UNION ALL SELECT count(*) FROM gup_theory WHERE gup_id = 'gup_10' AND theory_id = 'fixture_theory'
        UNION ALL SELECT count(*) FROM gup_vocabulary WHERE gup_id = 'gup_10' AND vocabulary_id = 'fixture_vocabulary'
        UNION ALL SELECT count(*) FROM gup_tool WHERE gup_id = 'gup_10' AND tool_id = 'fixture_body_tool'
        UNION ALL SELECT count(*) FROM gup_kick WHERE gup_id = 'gup_10' AND kick_id = 'fixture_kick'
        UNION ALL SELECT count(*) FROM gup_tul WHERE gup_id = 'gup_10' AND tul_id = 'fixture_tul'
        UNION ALL SELECT count(*) FROM gup_combat WHERE gup_id = 'gup_10' AND combat_id = 'fixture_combat'
    ) requirements;
    IF linked <> 7 THEN RAISE EXCEPTION 'missing/modified typed curriculum requirements'; END IF;
    IF NOT EXISTS (SELECT 1 FROM content_source
        WHERE id = 'citation_import_curriculum' AND content_id = 'gup_10'
        AND source_id = 'source_import_fixture' AND source_sha256 = repeat('a', 64)) THEN
        RAISE EXCEPTION 'curriculum citation missing';
    END IF;
    IF (SELECT name FROM content_entry WHERE id = 'fixture_position') <> 'Synthetic position'
        OR (SELECT cardinality(aliases) FROM vocabulary WHERE id = 'fixture_vocabulary') <> 2 THEN
        RAISE EXCEPTION 'conflicting import changed previous data';
    END IF;
    IF (SELECT translation FROM vocabulary WHERE id = 'dobok') <> U&'Uniforme de pr\00E1ctica'
        OR (SELECT review_status FROM content_entry WHERE id = 'gup_10') <> 'pending_human_review' THEN
        RAISE EXCEPTION 'UTF-8/review state not preserved';
    END IF;
END;
$$;
