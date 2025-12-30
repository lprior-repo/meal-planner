---
doc_id: tutorial/ci-integrations/jenkins
chunk_id: tutorial/ci-integrations/jenkins#chunk-2
heading_path: ["jenkins", "How it works"]
chunk_type: prose
tokens: 172
summary: "There are many ways to run Dagger on Jenkins."
---
There are many ways to run Dagger on Jenkins. The simplest way to get started is having a Jenkins agent with OCI compatible container runtime.

The general workflow looks like this:

1. Jenkins receives job trigger as usual.
2. Jenkins loads `Jenkinsfile` from repository or from UI configuration.
3. Jenkins parses the Groovy-based `Jenkinsfile` and downloads the Dagger CLI.
4. Jenkins find and executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the Jenkins agent.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. Job completes with success or failure, pipeline logs appear in Jenkins as usual
