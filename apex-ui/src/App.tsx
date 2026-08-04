import { useEffect, useState } from "react";

// Walking skeleton for Milestone 1 (REQ-4.3): proves apex-ui can reach
// apex-api over the Docker network. Replaced by the real app shell in
// Phase 6 (APEX-34 onward) — this component's only job is to fail loudly
// if the wiring between the two containers is broken.

type HealthState =
  | { status: "loading" }
  | { status: "ok"; message: string }
  | { status: "error"; message: string };

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "";

function App() {
  const [health, setHealth] = useState<HealthState>({ status: "loading" });

  useEffect(() => {
    const controller = new AbortController();

    fetch(`${API_BASE_URL}/health`, { signal: controller.signal })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`API responded with ${response.status}`);
        }
        return response.text();
      })
      .then((message) => setHealth({ status: "ok", message }))
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        const message = error instanceof Error ? error.message : "Unknown error";
        setHealth({ status: "error", message });
      });

    return () => controller.abort();
  }, []);

  return (
    <main>
      <h1>ApexMetrics</h1>
      <p>Project intelligence: an agile board plus a database-side analytics engine.</p>
      <p className="status" data-state={health.status === "ok" ? "ok" : health.status === "error" ? "error" : undefined}>
        {health.status === "loading" && "Checking connection to the API..."}
        {health.status === "ok" && `API reachable: ${health.message}`}
        {health.status === "error" && `API unreachable: ${health.message}`}
      </p>
    </main>
  );
}

export default App;
