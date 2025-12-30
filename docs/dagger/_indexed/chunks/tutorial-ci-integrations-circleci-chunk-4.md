---
doc_id: tutorial/ci-integrations/circleci
chunk_id: tutorial/ci-integrations/circleci#chunk-4
heading_path: ["circleci", "Examples"]
chunk_type: prose
tokens: 66
summary: "The examples below use the `docker` executor, which come with a Docker execution environment prec..."
---
The examples below use the `docker` executor, which come with a Docker execution environment preconfigured. If using a [different executor](https://circleci.com/docs/executor-intro), such as `machine`, you must install Docker in the execution environment before proceeding with the examples.

The following example demonstrates how to call a Dagger Function in a CircleCI workflow.

```yaml
