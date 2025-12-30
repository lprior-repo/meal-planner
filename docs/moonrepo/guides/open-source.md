# Open source usage

Although moon was designed for large monorepos, it can also be used for open source projects, especially when coupled with our [built-in continuous integration support](/docs/guides/ci).

However, a pain point with moon is that it has an explicitly configured version for each tool in the [toolchain](/docs/concepts/toolchain), but open source projects typically need to run checks against multiple versions! To mitigate this problem, you can set the matrix value as an environment variable, in the format of `MOON_<TOOL>_VERSION`.

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
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: ['ubuntu-latest', 'windows-latest']
        node-version: [16, 18, 20]
    steps:
      # Checkout repository
      - uses: 'actions/checkout@v4'
        with:
          fetch-depth: 0
      # Install Node.js
      - uses: 'actions/setup-node@v4'
      # Install dependencies
      - run: 'yarn install --immutable'
      # Run moon and affected tasks
      - run: 'yarn moon ci'
        env:
          MOON_NODE_VERSION: ${{ matrix.node-version }}
```

> **Info:** This example is only for GitHub actions, but the same mechanism can be applied to other CI environments.

## Reporting run results

We also suggest using our [`moonrepo/run-report-action`](https://github.com/marketplace/actions/moon-ci-run-reports) GitHub action. This action will report the results of a [`moon ci`](/docs/commands/ci) run to a pull request as a comment and workflow summary.

.github/workflows/ci.yml

```yaml
# ...
jobs:
  ci:
    name: 'CI'
    runs-on: 'ubuntu-latest'
    steps:
      # ...
      - run: 'yarn moon ci'
      - uses: 'moonrepo/run-report-action@v1'
        if: success() || failure()
        with:
          access-token: ${{ secrets.GITHUB_TOKEN }}
```
