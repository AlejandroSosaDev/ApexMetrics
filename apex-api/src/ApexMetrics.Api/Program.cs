// Walking skeleton for Milestone 1 (REQ-4.3): a single project just capable
// of booting in Docker and answering /health, so docker-compose.yml has a
// real container to orchestrate. Phase 2 (APEX-11) splits this into the
// four-project Clean Architecture layout ADR-0001 describes; nothing here
// survives that split unchanged except this endpoint's contract.

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/health", () => Results.Ok("healthy"));

app.Run();
