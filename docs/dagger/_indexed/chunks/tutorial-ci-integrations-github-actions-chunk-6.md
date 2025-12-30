---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-6
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: prose
tokens: 172
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: ubunt..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: ubuntu-latest
    steps:
      - name: Call Dagger Function
        uses: dagger/dagger-for-github@v8.2.0
        with:
          version: "latest"
          # assumes the Dagger Cloud token is in
          # a repository secret named DAGGER_CLOUD_TOKEN
          # set via the GitHub UI/CLI
          cloud-token: ${{ secrets.DAGGER_CLOUD_TOKEN }}
      - name: Chain in dagger shell
        run: container | from alpine | file /etc/os-release | contents
        shell: dagger {0}
```

The following is a more complex example demonstrating how to create a GitHub Actions workflow that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in your own GitHub repository.

```yaml
