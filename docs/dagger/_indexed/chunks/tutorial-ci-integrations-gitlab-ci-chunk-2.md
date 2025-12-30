---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-2
heading_path: ["gitlab-ci", "How it works"]
chunk_type: prose
tokens: 150
summary: "When running a CI pipeline with Dagger using GitLab CI, the general workflow looks like this:

1."
---
When running a CI pipeline with Dagger using GitLab CI, the general workflow looks like this:

1. GitLab receives a trigger based on a repository event.
2. GitLab begins processing the stages and jobs in the `.gitlab-ci.yml` file.
3. GitLab downloads the Dagger CLI.
4. GitLab executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the GitLab runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The pipeline completes with success or failure. Logs appear in GitLab as usual.
