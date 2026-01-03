---
doc_id: ops/moonrepo/open-source
chunk_id: ops/moonrepo/open-source#chunk-1
heading_path: ["Open source usage"]
chunk_type: prose
tokens: 338
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Open source usage</title>
  <description>Although moon was designed for large monorepos, it can also be used for open source projects, especially when coupled with our [built-in continuous integration support](/docs/guides/ci).</description>
  <created_at>2026-01-02T19:55:27.181726</created_at>
  <updated_at>2026-01-02T19:55:27.181726</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Reporting run results" level="2"/>
  </sections>
  <features>
    <feature>reporting_run_results</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/ci</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
    <entity relationship="uses">/docs/commands/ci</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>open,operations,moonrepo</tags>
</doc_metadata>
-->

# Open source usage

> **Context**: Although moon was designed for large monorepos, it can also be used for open source projects, especially when coupled with our [built-in continuous in

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
