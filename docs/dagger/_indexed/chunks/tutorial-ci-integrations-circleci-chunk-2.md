---
doc_id: tutorial/ci-integrations/circleci
chunk_id: tutorial/ci-integrations/circleci#chunk-2
heading_path: ["circleci", "How it works"]
chunk_type: prose
tokens: 192
summary: "When running a CI pipeline with Dagger using CircleCI, the general workflow looks like this:

1."
---
When running a CI pipeline with Dagger using CircleCI, the general workflow looks like this:

1. CircleCI receives a trigger based on a repository event.
2. CircleCI begins processing the jobs and steps in the `.circleci/config.yml` workflow file.
3. CircleCI downloads the Dagger CLI.
4. CircleCI executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the CircleCI runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The pipeline completes with success or failure. Logs appear in CircleCI as usual.

> **Note:** In a Dagger context, you won't have access to CircleCI's test splitting functionality. You will need to implement your own test distribution logic or run all tests in a single execution.
