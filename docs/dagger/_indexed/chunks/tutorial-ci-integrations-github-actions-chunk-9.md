---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-9
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: mixed
tokens: 135
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: depot..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: depot-ubuntu-24.04,dagger={{ version }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Call Dagger Function
        run: container | from alpine | file /etc/os-release | contents
        shell: dagger {0}
```

The following is a more complex example demonstrating how to create a GitHub Actions workflow that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in your own GitHub repository.

```yaml
