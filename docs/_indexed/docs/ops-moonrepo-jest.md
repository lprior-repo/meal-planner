---
id: ops/moonrepo/jest
title: "Jest example"
category: ops
tags: ["jest", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Jest example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Jest](https://jestjs.io/) into moon.</description>
  <created_at>2026-01-02T19:55:27.093626</created_at>
  <updated_at>2026-01-02T19:55:27.093626</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Setup" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Sharing" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to test a single file or folder?" level="3"/>
    <section name="How to use `projects`?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_test_a_single_file_or_folder</feature>
    <feature>how_to_use_projects</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>sharing</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>jest,operations,moonrepo</tags>
</doc_metadata>
-->

# Jest example

> **Context**: In this guide, you'll learn how to integrate [Jest](https://jestjs.io/) into moon.

In this guide, you'll learn how to integrate [Jest](https://jestjs.io/) into moon.

Begin by installing `jest` in your root. We suggest using the same version across the entire repository.

```
yarn add --dev jest
```

## Setup

Since testing is a universal workflow, add a `test` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  test:
    command:
      - 'jest'
      # Always run code coverage
      - '--coverage'
      # Dont fail if a project has no tests
      - '--passWithNoTests'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Project configs, any format
      - 'jest.config.*'
```

Projects can extend this task and provide additional parameters if need be, for example.

<project>/moon.yml

```yaml
tasks:
  test:
    args:
      # Disable caching for this project
      - '--no-cache'
```

## Configuration

### Root-level

A root-level Jest config is not required and should be avoided, instead, use a [preset](#sharing) to share configuration.

### Project-level

A project-level Jest config can be utilized by creating a `jest.config.<js|ts|cjs|mjs>` in the project root. This is optional, but necessary when defining project specific settings.

<project>/jest.config.js

```js
module.exports = {
  // Project specific settings
  testEnvironment: 'node',
};
```

### Sharing

To share configuration across projects, you can utilize Jest's built-in [`preset`](https://jestjs.io/docs/configuration#preset-string) functionality. If you're utilizing package workspaces, create a local package with the following content, otherwise publish the npm package for consumption.

packages/company-jest-preset/jest-preset.js

```js
module.exports = {
  testEnvironment: 'jsdom',
  watchman: true,
};
```

Within your project-level Jest config, you can extend the preset to inherit the settings.

<project>/jest.config.js

```js
module.exports = {
  preset: 'company-jest-preset',
};
```

> You can take this a step further by passing the `--preset` option in the [task above](#setup), so that all projects inherit the preset by default.

## FAQ

### How to test a single file or folder?

You can filter tests by passing a file name, folder name, glob, or regex pattern after `--`. Any passed files are relative from the project's root, regardless of where the `moon` command is being ran.

```
$ moon run <project>:test -- filename
```

### How to use `projects`?

With moon, there's no reason to use [`projects`](https://jestjs.io/docs/configuration#projects-arraystring--projectconfig) as the `test` task is ran *per* project. If you'd like to test multiple projects, use [`moon run :test`](/docs/commands/run).


## See Also

- [`.moon/tasks/node.yml`](/docs/config/tasks)
- [preset](#sharing)
- [task above](#setup)
- [`moon run :test`](/docs/commands/run)
