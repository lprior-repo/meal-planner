---
id: ops/moonrepo/prettier
title: "Prettier example"
category: ops
tags: ["prettier", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Prettier example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Prettier](https://prettier.io/) into moon.</description>
  <created_at>2026-01-02T19:55:27.103245</created_at>
  <updated_at>2026-01-02T19:55:27.103245</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Setup" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to use `--write`?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_use_--write</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>prettier,operations,moonrepo</tags>
</doc_metadata>
-->

# Prettier example

> **Context**: In this guide, you'll learn how to integrate [Prettier](https://prettier.io/) into moon.

In this guide, you'll learn how to integrate [Prettier](https://prettier.io/) into moon.

Begin by installing `prettier` in your root. We suggest using the same version across the entire repository.

```
yarn add --dev prettier
```

## Setup

Since code formatting is a universal workflow, add a `format` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  format:
    command:
      - 'prettier'
      # Use the same config for the entire repo
      - '--config'
      - '@in(4)'
      # Use the same ignore patterns as well
      - '--ignore-path'
      - '@in(3)'
      # Fail for unformatted code
      - '--check'
      # Run in current dir
      - '.'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Config and other files
      - '**/*.{md,mdx,yml,yaml,json}'
      # Root configs, any format
      - '/.prettierignore'
      - '/.prettierrc.*'
```

## Configuration

### Root-level

The root-level Prettier config is *required*, as it defines conventions and standards to apply to the entire repository.

.prettierrc.js

```js
module.exports = {
  arrowParens: 'always',
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: true,
};
```

The `.prettierignore` file must also be defined at the root, as [only 1 ignore file](https://prettier.io/docs/en/ignore.html#ignoring-files-prettierignore) can exist in a repository. We ensure this ignore file is used by passing `--ignore-path` above.

.prettierignore

```
node_modules/
*.min.js
*.map
*.snap
```

### Project-level

We suggest *against* project-level configurations, as the entire repository should be formatted using the same standards. However, if you're migrating code and need an escape hatch, [overrides in the root](https://prettier.io/docs/en/configuration.html#configuration-overrides) will work.

## FAQ

### How to use `--write`?

Unfortunately, this isn't currently possible, as the `prettier` binary itself requires either the `--check` or `--write` options, and since we're configuring `--check` in the task above, that takes precedence. This is also the preferred pattern as checks will run (and fail) in CI.

To work around this limitation, we suggest the following alternatives:

- Configure your editor to run Prettier on save.
- Define another task to write the formatted code, like `format-write`.


## See Also

- [`.moon/tasks/node.yml`](/docs/config/tasks)
