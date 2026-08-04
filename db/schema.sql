-- ApexMetrics database schema.
--
-- Naming convention: snake_case for every table and column. This is idiomatic
-- MySQL, and it sidesteps a real footgun: table names are case-sensitive on
-- Linux MySQL servers but not on Windows, so a schema written in PascalCase
-- to mirror C# entities silently breaks the day the API deploys to a Linux
-- container (REQ-4.2) while still working on a developer's Windows machine.
-- EF Core's naming convention translates between the two; Dapper's
-- hand-written analytics SQL (see docs/adr/0002) reads snake_case as-is.
--
-- Runs once, before seed.sql, via docker-entrypoint-initdb.d (see
-- docker-compose.yml). MYSQL_DATABASE has already been created by the mysql
-- image's entrypoint at this point.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ---------------------------------------------------------------------------
-- users
-- REQ-1.3: role carries the JWT claim distinguishing project manager from
-- developer. password_hash is sized for BCrypt today (~60 chars) with room
-- for a longer algorithm (e.g. Argon2id) without a migration (REQ-1.2).
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name          VARCHAR(120)    NOT NULL,
    email         VARCHAR(255)    NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,
    role          ENUM('admin', 'developer') NOT NULL,
    created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                   ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------------
-- projects
-- manager_id is an admin. Enforced by the application layer, not a DB
-- constraint: a CHECK against another table's column is not expressible in
-- MySQL, and this is exactly the kind of business rule ADR-0001 assigns to
-- the domain rather than the schema.
-- ---------------------------------------------------------------------------
CREATE TABLE projects (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(160)    NOT NULL,
    description TEXT            NULL,
    manager_id  BIGINT UNSIGNED NOT NULL,
    created_at  DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at  DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                 ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_projects_manager
        FOREIGN KEY (manager_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;
-- InnoDB auto-indexes manager_id as the leftmost column of its own foreign
-- key, so no separate index is added here.

-- ---------------------------------------------------------------------------
-- tasks
--
-- status: REQ-2.2's four statuses. The ENUM guarantees only a valid value is
-- ever stored, but it cannot express "strictly sequential" — that a task may
-- only move Backlog -> To Do -> In Progress -> Done one step at a time. That
-- rule lives in the domain's task state machine (see the roadmap's Phase 2),
-- not here; the ENUM is defence in depth against a value the state machine
-- was bypassed for, not the enforcement mechanism itself.
--
-- estimation_points vs estimated_hours: two independent required measures,
-- not duplicates. See docs/adr/0004 for why.
--
-- status_changed_at: when the task entered its CURRENT status. REQ-3.3's
-- bottleneck detection ("in_progress for more than 5 days") reads off this
-- column rather than created_at. A full status-change history table would
-- also answer this and more, but nothing in the requirements needs "more"
-- yet, and REQ-3 is explicit that the query must stay simple enough to run
-- at the database layer. Updating this column on every transition is an
-- application-layer responsibility, not a trigger — see CLAUDE.md section 3
-- on keeping business logic out of the database.
-- ---------------------------------------------------------------------------
CREATE TABLE tasks (
    id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    project_id         BIGINT UNSIGNED NOT NULL,
    assignee_id        BIGINT UNSIGNED NOT NULL,
    title              VARCHAR(200)    NOT NULL,
    description        TEXT            NOT NULL,
    status             ENUM('backlog', 'to_do', 'in_progress', 'done')
                                       NOT NULL DEFAULT 'backlog',
    estimation_points  TINYINT UNSIGNED NOT NULL,
    estimated_hours    DECIMAL(6, 2)   NOT NULL,
    logged_hours       DECIMAL(6, 2)   NOT NULL DEFAULT 0.00,
    status_changed_at  DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    created_at         DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                       ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_tasks_project
        FOREIGN KEY (project_id) REFERENCES projects (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_tasks_assignee
        FOREIGN KEY (assignee_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_tasks_estimation_points
        CHECK (estimation_points IN (1, 2, 3, 5, 8, 13)),
    CONSTRAINT chk_tasks_estimated_hours_positive
        CHECK (estimated_hours > 0),
    CONSTRAINT chk_tasks_logged_hours_non_negative
        CHECK (logged_hours >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- project_id and assignee_id already carry a single-column index from their
-- foreign keys. The composite indexes below exist for the specific access
-- patterns the three analytics queries need (docs/adr/0002); each is
-- revisited with a measured EXPLAIN plan in Phase 5 (APEX-31) once the real
-- queries exist; these are the obvious starting shapes, not the final answer.
CREATE INDEX idx_tasks_assignee_status
    ON tasks (assignee_id, status);
-- REQ-3.1: per-developer count and point sum filtered to in_progress.

CREATE INDEX idx_tasks_status_changed
    ON tasks (status, status_changed_at);
-- REQ-3.3: bottleneck lookup filters status = 'in_progress' and ranges
-- status_changed_at. status leads the composite because it is an equality
-- predicate; status_changed_at trails as the ranged column, matching the
-- leftmost-prefix rule for how MySQL can use a composite index.
