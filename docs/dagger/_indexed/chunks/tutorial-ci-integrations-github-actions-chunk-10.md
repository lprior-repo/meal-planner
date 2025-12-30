---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-10
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: mixed
tokens: 177
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  test:
    name: test
    runs-on: depot-u..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  test:
    name: test
    runs-on: depot-ubuntu-24.04,dagger=0.19.7
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Test
        run: dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.1 call test --source=.
  build:
    name: build
    runs-on: depot-ubuntu-24.04,dagger=0.19.7
    needs: test
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build
        run: dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.1 call build-container --source=. --args=. publish --address=ttl.sh/my-app-$RANDOM
```

> **Warning:** Always ensure that the same Dagger versions are specified in the `runs-on` and `version` clauses of the workflow definition.

More information is available in the [Dagger for GitHub page](https://github.com/marketplace/actions/dagger-for-github) and in the [Depot documentation](https://depot.dev/docs/).

### SSH configuration

When using SSH keys in GitHub Actions, ensure proper SSH agent setup:

```yaml
- name: Set up SSH
  run: |
    eval "$(ssh-agent -s)"
    ssh-add - <<< '${{ secrets.SSH_PRIVATE_KEY }}'
```

Replace `${{ secrets.SSH_PRIVATE_KEY }}` with your provider secret containing the private key.
