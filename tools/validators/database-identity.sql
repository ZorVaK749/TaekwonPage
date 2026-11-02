-- Local identity foundation (V7, C1: JWT local autoemitido). Everything is
-- rolled back, including the deliberate test accounts: production seeds none.
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
-- Seed: exactly the four documented roles and zero accounts or assignments.
DO $$
BEGIN
    IF (SELECT count(*) FROM role) <> 4 THEN
        RAISE EXCEPTION 'role seed must contain exactly the four documented roles';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM role WHERE name = 'ROLE_GUEST')
        OR NOT EXISTS (SELECT 1 FROM role WHERE name = 'ROLE_STUDENT')
        OR NOT EXISTS (SELECT 1 FROM role WHERE name = 'ROLE_ADMIN')
        OR NOT EXISTS (SELECT 1 FROM role WHERE name = 'ROLE_DEVELOPER') THEN
        RAISE EXCEPTION 'role seed lost a documented role';
    END IF;
    IF (SELECT count(*) FROM app_user) <> 0 THEN
        RAISE EXCEPTION 'no user may be seeded by a migration';
    END IF;
    IF (SELECT count(*) FROM user_role) <> 0 THEN
        RAISE EXCEPTION 'no role assignment may be seeded by a migration';
    END IF;
END;
$$;
-- One deliberate account and one assignment; rolled back with the transaction.
INSERT INTO app_user (id, username, password_hash) VALUES
    ('user_test_local', 'test.local', '$2a$10$' || repeat('B', 53));
INSERT INTO user_role (user_id, role_name) VALUES ('user_test_local', 'ROLE_STUDENT');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.expect_rejection($q$INSERT INTO app_user (id, username, password_hash) VALUES ('user_other', 'test.local', '$2a$10$' || repeat('C', 53))$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO app_user (id, username, password_hash) VALUES ('Bad_Id', 'unique.name', '$2a$10$' || repeat('C', 53))$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO app_user (id, username, password_hash) VALUES ('user_short_name', 'ab', '$2a$10$' || repeat('C', 53))$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO app_user (id, username, password_hash) VALUES ('user_bad_chars', 'user name!', '$2a$10$' || repeat('C', 53))$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO app_user (id, username, password_hash) VALUES ('user_plain_secret', 'plain.name', 'not-a-bcrypt-hash')$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO role (name) VALUES ('ROLE_SUPERUSER')$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO user_role (user_id, role_name) VALUES ('user_ghost', 'ROLE_STUDENT')$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO user_role (user_id, role_name) VALUES ('user_test_local', 'ROLE_GHOST')$q$);
SELECT pg_temp.expect_rejection($q$INSERT INTO user_role (user_id, role_name) VALUES ('user_test_local', 'ROLE_STUDENT')$q$);
SELECT pg_temp.expect_rejection($q$UPDATE app_user SET id = 'user_renamed' WHERE id = 'user_test_local'$q$);
SELECT pg_temp.expect_rejection($q$DELETE FROM role WHERE name = 'ROLE_STUDENT'$q$);
-- The account shape the service actually reads back.
DO $$
DECLARE
    stored text;
BEGIN
    SELECT password_hash INTO stored FROM app_user WHERE id = 'user_test_local';
    IF stored !~ '^\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}$' THEN
        RAISE EXCEPTION 'stored hash does not match the bcrypt shape';
    END IF;
    IF (SELECT count(*) FROM user_role WHERE user_id = 'user_test_local') <> 1 THEN
        RAISE EXCEPTION 'test account lost its assignment';
    END IF;
END;
$$;
ROLLBACK;
