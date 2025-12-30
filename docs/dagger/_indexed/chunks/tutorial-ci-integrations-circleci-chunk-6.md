---
doc_id: tutorial/ci-integrations/circleci
chunk_id: tutorial/ci-integrations/circleci#chunk-6
heading_path: ["circleci", "in a project environment variable named DAGGER_CLOUD_TOKEN"]
chunk_type: code
tokens: 88
summary: "```

The following is a more complex example demonstrating how to create a CircleCI workflow that..."
---
```

The following is a more complex example demonstrating how to create a CircleCI workflow that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in the repository connected to the CircleCI project.

```yaml
