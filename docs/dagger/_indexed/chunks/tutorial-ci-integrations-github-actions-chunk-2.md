---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-2
heading_path: ["github-actions", "How it works"]
chunk_type: prose
tokens: 443
summary: "Depending on whether you choose a standard GitHub Actions runner or a Dagger Powered Depot GitHub..."
---
Depending on whether you choose a standard GitHub Actions runner or a Dagger Powered Depot GitHub Actions Runner, here's how it works.

### Standard GitHub Runner

When running a CI pipeline with Dagger using a standard GitHub Actions runner, the general workflow looks like this:

1. GitHub receives a workflow trigger based on a repository event.
2. GitHub begins processing the jobs and steps in the workflow.
3. GitHub finds the "Dagger for GitHub" action and passes control to it.
4. The "Dagger for GitHub" action calls the Dagger CLI with the specified sub-command, module, function name, and arguments.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the GitHub Actions runner.
6. The Dagger CLI executes the specified sub-command and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The workflow completes with success or failure. Logs appear in GitHub as usual.

### Depot Runner

When running a CI pipeline on a Dagger Powered Depot GitHub Actions Runner, the general workflow looks like this:

1. GitHub emits a webhook event which triggers a job in a GitHub Actions workflow
2. Depot receives this event, processes it, and launches an isolated Depot GitHub Actions Runner.
3. Each Depot GitHub Actions Runner is automatically connected to an already running Dagger Engine (this exists outside of the Depot GitHub Actions Runner).
   - The external Dagger Engine comes with persistent caching pre-configured.
4. The Depot GitHub Actions Runner has the Dagger CLI pre-installed.
   - The Dagger CLI running inside the Depot GitHub Actions Runner gets automatically connected to Dagger Cloud.
   - The Dagger CLI is also pre-configured to connect to the external Dagger Engine with persistent caching
5. The "Dagger for GitHub" GitHub Action calls the Dagger CLI with the specified sub-command, module, function name, and arguments.
6. The Dagger CLI executes the specified sub-command and sends telemetry to Dagger Cloud.
7. The workflow completes with success or failure. Logs appear in GitHub as usual. They also appear in Dagger Cloud.
