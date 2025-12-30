---
doc_id: tutorial/ci-integrations/aws-codebuild
chunk_id: tutorial/ci-integrations/aws-codebuild#chunk-2
heading_path: ["aws-codebuild", "How it works"]
chunk_type: prose
tokens: 159
summary: "When running a CI pipeline with Dagger using AWS CodeBuild, the general workflow looks like this:..."
---
When running a CI pipeline with Dagger using AWS CodeBuild, the general workflow looks like this:

1. AWS CodeBuild receives a trigger based on a repository event.
2. AWS CodeBuild begins processing the build instructions in the `buildspec.yml` file.
3. AWS CodeBuild downloads the Dagger CLI.
4. AWS CodeBuild executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the GitLab runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The AWS CodePipeline completes with success or failure. Logs appear in the AWS CodeBuild interface as usual.
