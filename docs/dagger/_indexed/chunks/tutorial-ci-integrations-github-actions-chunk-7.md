---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-7
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: prose
tokens: 207
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  test:
    name: test
    runs-on: ubuntu-..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  test:
    name: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Test
        uses: dagger/dagger-for-github@v8.2.0
        with:
          version: "latest"
          verb: call
          module: github.com/kpenfound/dagger-modules/golang@v0.2.0
          args: test --source=.
          # assumes the Dagger Cloud token is in
          # a repository secret named DAGGER_CLOUD_TOKEN
          # set via the GitHub UI/CLI
          cloud-token: ${{ secrets.DAGGER_CLOUD_TOKEN }}
  build:
    name: build
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Call Dagger Function
        uses: dagger/dagger-for-github@v8.2.0
        with:
          version: "latest"
          verb: call
          module: github.com/kpenfound/dagger-modules/golang@v0.2.0
          args: build-container --source=. --args=. publish --address=ttl.sh/my-app-$RANDOM
          # assumes the Dagger Cloud token is in
          # a repository secret named DAGGER_CLOUD_TOKEN
          # set via the GitHub UI/CLI
          cloud-token: ${{ secrets.DAGGER_CLOUD_TOKEN }}
```

More information is available in the [Dagger for GitHub page](https://github.com/marketplace/actions/dagger-for-github).

### Depot Runner

The following example demonstrates how to call a Dagger Function on a Dagger Powered Depot runner in a GitHub Actions workflow. The `runs-on` clause specifies the runner and Dagger versions.

```yaml
