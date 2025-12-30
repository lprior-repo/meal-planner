---
doc_id: tutorial/ci-integrations/teamcity
chunk_id: tutorial/ci-integrations/teamcity#chunk-2
heading_path: ["teamcity", "How it works"]
chunk_type: prose
tokens: 125
summary: "When running a CI pipeline with Dagger using TeamCity, the general workflow looks like this:

1."
---
When running a CI pipeline with Dagger using TeamCity, the general workflow looks like this:

1. A new build is triggered.
2. The build is sent to an available TeamCity agent.
3. The Dagger Recipe installs the required version of Dagger CLI on the agent.
4. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one.
5. The Dagger CLI executes the specified command and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
6. The build completes successfully or fails. Logs appear in TeamCity as usual.
