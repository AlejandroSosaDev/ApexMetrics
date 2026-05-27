1. Project Overview & Business Problem
Tech companies struggle to track development bottlenecks and team velocity accurately across multiple software projects. ApexMetrics is a lightweight, high-performance project intelligence tool. It allows project managers to organize tasks using an agile board and automatically computes deep analytics, resource workload constraints, and velocity tracking.

2. Epics & Functional Requirements
Epic 1: Secure Identity & Workspace Management (Auth)
REQ-1.1: The system must implement stateless authentication using JSON Web Tokens (JWT).

REQ-1.2: Passwords must be hashed using industry standards (BCrypt or Argon2 id).

REQ-1.3: Tokens must include role claims: Admin (Project Manager) and Developer.

REQ-1.4: API requests to protected endpoints must validate the JWT via a Bearer token header. Unauthorized requests must return HTTP 401.

Epic 2: Dynamic Kanban Board & Core Task Lifecycle
REQ-2.1: Users must be able to create, read, update, and change states of "Tasks" within a specific project.

REQ-2.2: Tasks must have 4 strict sequential statuses: Backlog, To Do, In Progress, Done.

REQ-2.3: Every task must require: Title, Description, Assigned User, Estimation Points (1, 2, 3, 5, 8, 13), and logged hours.

REQ-2.4: The Frontend must represent this as an interactive board where moving a task sends an asynchronous patch request to update the status in MySQL without reloading the view.

Epic 3: Advanced Analytics Engine (The SQL Challenge)
The system must expose a specific analytics dashboard accessible only by Admins via a single optimized endpoint (GET /api/v1/analytics/overview). This endpoint cannot load raw data and process it in memory; all data aggregation must happen at the MySQL database layer.

REQ-3.1 (Multi-Table Joins & Grouping): Calculate the Resource Allocation Index: List all developers, the count of tasks currently assigned to them in the In Progress state, and the total sum of estimation points allocated to them.

REQ-3.2 (Complex Aggregations): Calculate Project Efficiency Metrics: Compute the total estimated hours vs. actual logged hours per project, displaying the variance percentage (((Estimated - Logged) / Estimated) * 100).

REQ-3.3 (Data Relational Analysis): Identify "Bottleneck Tasks": Return tasks that have been in the In Progress status for more than 5 days, linking project details, manager data, and assignee details in a single complex relational payload.

3. Non-Functional & DevOps Requirements
Infrastructure Containerization (Docker)
REQ-4.1: The entire application must run isolated inside Docker containers.

REQ-4.2: A docker-compose.yml file must orchestrate exactly three services:

apex-db: A MySQL container with persisted storage via a Docker volume.

apex-api: The backend service (.NET or Laravel).

apex-ui: The frontend application (React or Nuxt).

REQ-4.3: Running docker-compose up --build must boot up the entire ecosystem. The backend must wait for the database to be healthy before starting.

REQ-4.4: The database container must initialize with a database seed script (seed.sql) containing at least 3 mock projects, 5 mock users, and 30 sample tasks with realistic relational data for the analytical dashboard to display data immediately.