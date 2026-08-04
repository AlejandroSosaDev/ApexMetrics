-- Demo dataset for ApexMetrics (REQ-4.4). Runs once, after schema.sql, via
-- docker-entrypoint-initdb.d.
--
-- Every date is relative to NOW() rather than a hardcoded literal. A seed
-- with fixed calendar dates looks fresh the day it is written and looks
-- broken six months later, when "bottleneck" tasks would no longer be in
-- the past relative to today. Relative dates keep the demo honest at any
-- point in the future.
--
-- This file is inserted into a database that is empty by construction (it
-- only runs when the data volume has no existing data), so relying on
-- auto_increment starting at 1, in this exact insert order, is safe: users
-- 1-5 are Elena, Marcus, Priya, Diego, Sofia in that order; projects 1-4 are
-- Apex Mobile Revamp, Internal Analytics Platform, Customer Portal
-- Migration, Q3 Planning Sandbox in that order.
--
-- All five demo accounts share one password for convenience: ApexDemo123!
-- (bcrypt, cost factor 11 — the default this project documents for
-- BCrypt.Net-Next in ADR-0003). This is seed data for a public portfolio
-- demo, not a real credential, so a shared password is intentional rather
-- than an oversight.

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- Users: 1 admin (project manager) + 4 developers.
--
-- Deliberately uneven workload, because "list all developers" (REQ-3.1) is
-- only a meaningful test if the result includes developers an INNER JOIN
-- would hide:
--   Marcus  — heavy load: 3 tasks currently In Progress.
--   Priya   — light load: 1 task currently In Progress.
--   Diego   — has tasks, but none currently In Progress (proves the query
--             filters by status, not merely "has an assignment").
--   Sofia   — zero tasks assigned, ever. The one an INNER JOIN would silently
--             drop from the resource allocation report.
-- ---------------------------------------------------------------------------
INSERT INTO users (name, email, password_hash, role) VALUES
    ('Elena Vasquez',   'elena.vasquez@apexmetrics.dev',  '$2b$11$jHazt1Aj88tdkg09Ix.Uc.LUQ/zFo/P1jiFEogpWRRF/VEC5APabC', 'admin'),
    ('Marcus Chen',     'marcus.chen@apexmetrics.dev',     '$2b$11$jHazt1Aj88tdkg09Ix.Uc.LUQ/zFo/P1jiFEogpWRRF/VEC5APabC', 'developer'),
    ('Priya Sharma',    'priya.sharma@apexmetrics.dev',    '$2b$11$jHazt1Aj88tdkg09Ix.Uc.LUQ/zFo/P1jiFEogpWRRF/VEC5APabC', 'developer'),
    ('Diego Fernandez', 'diego.fernandez@apexmetrics.dev', '$2b$11$jHazt1Aj88tdkg09Ix.Uc.LUQ/zFo/P1jiFEogpWRRF/VEC5APabC', 'developer'),
    ('Sofia Novak',     'sofia.novak@apexmetrics.dev',     '$2b$11$jHazt1Aj88tdkg09Ix.Uc.LUQ/zFo/P1jiFEogpWRRF/VEC5APabC', 'developer');

-- ---------------------------------------------------------------------------
-- Projects: 3 satisfy REQ-4.4's minimum. The 4th, with zero tasks, exists on
-- purpose — it is the only way to exercise REQ-3.2's division-by-zero case
-- (a project with SUM(estimated_hours) = 0) against real data instead of a
-- synthetic unit test fixture.
-- ---------------------------------------------------------------------------
INSERT INTO projects (name, description, manager_id) VALUES
    ('Apex Mobile Revamp',
     'Rebuild the mobile client on the new design system.', 1),
    ('Internal Analytics Platform',
     'Self-serve reporting for the data team.', 1),
    ('Customer Portal Migration',
     'Move the legacy customer portal onto the new auth stack.', 1),
    ('Q3 Planning Sandbox',
     'Newly created; no tasks yet. Exists to prove the efficiency query does not divide by zero.', 1);

-- ---------------------------------------------------------------------------
-- Tasks: 30 total across the first 3 projects (REQ-4.4), none on Q3 Planning
-- Sandbox. status_changed_at drives REQ-3.3's bottleneck detection; rows are
-- annotated where the value is chosen to land on a specific side of the
-- 5-day threshold.
--
-- Note for Phase 5 (APEX-27): REQ-3.1 asks for "the total sum of estimation
-- points allocated to them" without repeating "in the In Progress state" the
-- way it does for the count. This dataset supports both readings — points
-- summed only over In Progress tasks, or over every task regardless of
-- status — since assignees here have varied points across every status. The
-- choice is made, and justified, when that query is written.
-- ---------------------------------------------------------------------------

-- --- Project 1: Apex Mobile Revamp (12 tasks) -------------------------------
INSERT INTO tasks
    (project_id, assignee_id, title, description, status, estimation_points, estimated_hours, logged_hours, status_changed_at, created_at)
VALUES
    -- Marcus: 2 of his 3 In Progress tasks live here, both past the 5-day bottleneck threshold.
    (1, 2, 'Rebuild navigation shell on the new design tokens',
     'Swap the legacy tab bar and drawer for the design system primitives.',
     'in_progress', 8, 20.00, 14.00, DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY)),
    (1, 2, 'Offline sync for the task list screen',
     'Cache the last-known task list and reconcile on reconnect.',
     'in_progress', 5, 12.00, 10.00, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
    (1, 4, 'Migrate push notification provider',
     'Swap the deprecated push SDK for the maintained replacement.',
     'done', 3, 6.00, 7.00, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 20 DAY)),
    (1, 4, 'Biometric login on supported devices',
     'Face/fingerprint unlock as an alternative to the PIN screen.',
     'done', 5, 10.00, 9.00, DATE_SUB(NOW(), INTERVAL 18 DAY), DATE_SUB(NOW(), INTERVAL 27 DAY)),
    (1, 4, 'Deep-link handling for shared task URLs',
     'Open the app directly to a task when a shared link is tapped.',
     'to_do', 2, 4.00, 0.00, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
    (1, 3, 'Dark mode audit for the board view',
     'Pass every board component through the dark theme token set.',
     'backlog', 1, 2.00, 0.00, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
    (1, 3, 'Accessibility pass on the task detail sheet',
     'Screen reader labels and focus order for the detail bottom sheet.',
     'done', 8, 16.00, 15.00, DATE_SUB(NOW(), INTERVAL 9 DAY), DATE_SUB(NOW(), INTERVAL 22 DAY)),
    (1, 2, 'Reduce cold start time below 2 seconds',
     'Profile and trim the startup path on the reference device.',
     'backlog', 3, 8.00, 0.00, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
    (1, 4, 'Replace the legacy chart library',
     'Migrate the velocity sparkline off the unmaintained chart package.',
     'to_do', 13, 30.00, 0.00, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
    (1, 3, 'Localise onboarding flow',
     'Add Spanish and Portuguese strings to the first-run screens.',
     'done', 2, 4.00, 3.00, DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 19 DAY)),
    (1, 2, 'Crash triage: background sync race condition',
     'Fix the race between manual refresh and the background sync timer.',
     'done', 5, 12.00, 13.00, DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 16 DAY)),
    (1, 4, 'Retire the old feature-flag SDK',
     'Remove the deprecated flag client once the new one is confirmed stable.',
     'backlog', 1, 3.00, 0.00, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY));

-- --- Project 2: Internal Analytics Platform (10 tasks) ----------------------
INSERT INTO tasks
    (project_id, assignee_id, title, description, status, estimation_points, estimated_hours, logged_hours, status_changed_at, created_at)
VALUES
    -- Marcus's 3rd In Progress task, deliberately inside the 5-day window (not a bottleneck).
    (2, 2, 'Wire the resource allocation query to the dashboard',
     'Connect the REQ-3.1 endpoint to the allocation chart.',
     'in_progress', 3, 8.00, 4.00, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
    -- Priya's only In Progress task, also inside the window.
    (2, 3, 'Build the efficiency variance chart',
     'Render REQ-3.2 variance with a clear over/under budget encoding.',
     'in_progress', 5, 10.00, 3.00, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
    (2, 4, 'Design the bottleneck detail payload',
     'Shape the REQ-3.3 response: project, manager and assignee in one row.',
     'done', 8, 18.00, 20.00, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 21 DAY)),
    (2, 4, 'Add EXPLAIN capture to the query benchmark doc',
     'Script that runs each analytics query and appends its plan to the doc.',
     'done', 3, 6.00, 5.00, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY)),
    (2, 3, 'Admin-only route guard on the dashboard',
     'Redirect non-admin roles away from the analytics routes client-side.',
     'to_do', 2, 4.00, 0.00, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
    (2, 2, 'Empty-state design for zero-task projects',
     'Cover the Q3 Planning Sandbox case in the efficiency chart.',
     'backlog', 1, 2.00, 0.00, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
    (2, 4, 'Seed data regeneration script',
     'One command to reset apex-db back to a clean demo state.',
     'backlog', 5, 11.00, 0.00, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
    (2, 3, 'CSV export for the bottleneck table',
     'Let an admin download the current bottleneck list.',
     'done', 1, 2.00, 2.00, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY)),
    (2, 4, 'Cache the analytics endpoint response for 60 seconds',
     'Avoid re-running all three aggregations on every dashboard refresh.',
     'to_do', 8, 19.00, 0.00, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
    (2, 2, 'Keyboard navigation for the bottleneck table',
     'Sortable columns operable without a mouse.',
     'done', 2, 5.00, 4.00, DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY));

-- --- Project 3: Customer Portal Migration (8 tasks) -------------------------
-- No In Progress tasks here: every developer's In Progress count and points
-- for REQ-3.1 are already fully determined by Projects 1 and 2 above.
INSERT INTO tasks
    (project_id, assignee_id, title, description, status, estimation_points, estimated_hours, logged_hours, status_changed_at, created_at)
VALUES
    (3, 4, 'Migrate session storage to the new auth service',
     'Move active sessions without forcing a re-login.',
     'done', 5, 11.00, 10.00, DATE_SUB(NOW(), INTERVAL 9 DAY), DATE_SUB(NOW(), INTERVAL 17 DAY)),
    (3, 3, 'Password reset flow on the new stack',
     'Rebuild the reset-link email and confirmation screen.',
     'backlog', 3, 7.00, 0.00, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY)),
    (3, 2, 'Legacy cookie cleanup on first login',
     'Clear stale session cookies from the old portal on first sign-in.',
     'done', 8, 17.00, 19.00, DATE_SUB(NOW(), INTERVAL 13 DAY), DATE_SUB(NOW(), INTERVAL 24 DAY)),
    (3, 4, 'Rate limit the password reset endpoint',
     'Cap reset requests per account per hour.',
     'to_do', 1, 2.00, 0.00, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
    (3, 3, 'Account recovery via backup email',
     'Secondary recovery path when the primary email is unreachable.',
     'done', 5, 10.00, 9.00, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY)),
    (3, 2, 'Audit log for admin role changes',
     'Record who granted or revoked Admin on which account.',
     'backlog', 2, 5.00, 0.00, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
    (3, 4, 'Deprecate the legacy /login endpoint',
     'Return 410 Gone once the new auth flow is confirmed stable.',
     'backlog', 3, 6.00, 0.00, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY)),
    (3, 3, 'Session timeout warning modal',
     'Warn the user 60 seconds before an idle session expires.',
     'to_do', 8, 18.00, 0.00, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY));
