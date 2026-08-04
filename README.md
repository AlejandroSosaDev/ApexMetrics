# ApexMetrics

Project intelligence for engineering teams: an agile board that turns day-to-day
task activity into velocity, workload and bottleneck analytics.

> **Status: in development.** This README grows with the project. See
> [docs/requirements.md](docs/requirements.md) for the full specification and
> [docs/adr/](docs/adr/) for the reasoning behind each architectural decision.

## The problem

Engineering organisations track *what* their teams are doing but rarely *where
the work is getting stuck*. ApexMetrics computes resource allocation, estimation
accuracy and bottleneck detection directly from the task lifecycle, so a project
manager sees the constraint instead of inferring it.

## Architecture at a glance

Three containers, orchestrated by a single `docker-compose.yml`:

| Service | Stack | Responsibility |
| --- | --- | --- |
| `apex-ui` | React 19 · TypeScript · Vite · Tailwind | Interactive Kanban board and analytics dashboard |
| `apex-api` | .NET 10 · ASP.NET Core · Clean Architecture | REST API, authentication, analytics engine |
| `apex-db` | MySQL 8.4 | Relational store with a seeded demo dataset |

### The decision worth reading about

The analytics engine deliberately **does not** use the ORM. Writes go through
Entity Framework Core; the analytics endpoint uses hand-written SQL through
Dapper and returns three aggregations in a single round trip.

Aggregating in the database rather than in application memory is a requirement of
the specification, but it is also the more interesting engineering problem, and
it is documented as such: see `docs/analytics-benchmark.md` for the execution
plans, the index design, and measurements against a naive implementation.

## Getting started

```bash
docker compose up --build
```

The API waits for the database to report healthy before starting, and the
database initialises with a seeded dataset, so the analytics dashboard has
meaningful data on first load.

| Service | URL |
| --- | --- |
| Frontend | http://localhost:5173 |
| API | http://localhost:8080 |
| API reference | http://localhost:8080/scalar |

## Development

Requirements, workflow conventions and the definition of done live in
[CLAUDE.md](CLAUDE.md).

## License

[MIT](LICENSE)
