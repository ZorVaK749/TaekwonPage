-- Local identity foundation (C1: locally self-issued JWT). Users, roles and
-- credential storage only: no user, password, token or role assignment is
-- seeded here. Provisioning is a deliberate, separate step; ROLE_GUEST exists
-- as a documented role but never maps to a row in app_user.
CREATE TABLE role (
    name text PRIMARY KEY CHECK (name IN
        ('ROLE_GUEST', 'ROLE_STUDENT', 'ROLE_ADMIN', 'ROLE_DEVELOPER'))
);

INSERT INTO role (name) VALUES
    ('ROLE_GUEST'), ('ROLE_STUDENT'), ('ROLE_ADMIN'), ('ROLE_DEVELOPER');

CREATE TABLE app_user (
    id canonical_id PRIMARY KEY,
    username text NOT NULL UNIQUE
        CHECK (char_length(username) BETWEEN 3 AND 64 AND username ~ '^[A-Za-z0-9._-]+$'),
    password_hash text NOT NULL
        CHECK (password_hash ~ '^\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}$'),
    enabled boolean NOT NULL DEFAULT TRUE,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_role (
    user_id canonical_id NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    role_name text NOT NULL REFERENCES role (name),
    PRIMARY KEY (user_id, role_name)
);
