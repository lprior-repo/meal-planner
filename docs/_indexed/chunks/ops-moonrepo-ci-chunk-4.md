---
doc_id: ops/moonrepo/ci
chunk_id: ops/moonrepo/ci#chunk-4
heading_path: ["ci", "Integrating"]
chunk_type: code
tokens: 195
summary: "Integrating"
---

## Integrating

The following examples can be referenced for setting up moon and its CI workflow in popular providers. For GitHub, we're using our [`setup-toolchain` action](https://github.com/moonrepo/setup-toolchain) to install moon. For other providers, we assume moon is an npm dependency and must be installed with Node.js.

### GitHub

.github/workflows/ci.yml

```yaml
name: 'Pipeline'
on:
  push:
    branches:
      - 'master'
  pull_request:
jobs:
  ci:
    name: 'CI'
    runs-on: 'ubuntu-latest'
    steps:
      - uses: 'actions/checkout@v4'
        with:
          fetch-depth: 0
      - uses: 'moonrepo/setup-toolchain@v0'
      - run: 'moon ci'
```

### Buildkite

.buildkite/pipeline.yml

```yaml
steps:
  - label: 'CI'
    commands:
      - 'yarn install --immutable'
      - 'moon ci'
```

### CircleCI

.circleci/config.yml

```yaml
version: 2.1
orbs:
  node: 'circleci/node@5.0.2'
jobs:
  ci:
    docker:
      - image: 'cimg/base:stable'
    steps:
      - checkout
      - node/install:
          install-yarn: true
          node-version: '16.13'
      - node/install-packages:
          check-cache: 'always'
          pkg-manager: 'yarn-berry'
      - run: 'moon ci'
workflows:
  pipeline:
    jobs:
      - 'ci'
```

### TravisCI

.travis.yml

```yaml
language: node_js
node_js:
  - 16
cache: yarn
script: 'moon ci'
```
