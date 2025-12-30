---
doc_id: tutorial/ci-integrations/azure-pipelines
chunk_id: tutorial/ci-integrations/azure-pipelines#chunk-2
heading_path: ["azure-pipelines", "How it works"]
chunk_type: prose
tokens: 155
summary: "When running a CI pipeline with Dagger using Azure Pipelines, the general workflow looks like thi..."
---
When running a CI pipeline with Dagger using Azure Pipelines, the general workflow looks like this:

1. Azure Pipelines receives a trigger based on a repository event.
2. Azure Pipelines begins processing the steps in the `azure-pipelines.yml` file.
3. Azure Pipelines downloads the Dagger CLI.
4. Azure Pipelines executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the Azure Pipelines runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The pipeline completes with success or failure. Logs appear in Azure Pipelines as usual.
