---
id: tutorial/moonrepo/nest
title: "Nest example"
category: tutorial
tags: ["tutorial", "beginner", "nest", "moonrepo"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Nest example</title>
  <description>In this guide, you&apos;ll learn how to integrate [NestJS](https://nestjs.com/) into moon.</description>
  <created_at>2026-01-02T19:55:27.095717</created_at>
  <updated_at>2026-01-02T19:55:27.095717</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tutorial,beginner,nest,moonrepo</tags>
</doc_metadata>
-->

# Nest example

> **Context**: In this guide, you'll learn how to integrate [NestJS](https://nestjs.com/) into moon.

In this guide, you'll learn how to integrate [NestJS](https://nestjs.com/) into moon.

Begin by creating a new NestJS project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
npx @nestjs/cli@latest new nestjs-app --skip-git
```

> View the [official NestJS docs](https://docs.nestjs.com/first-steps) for a more in-depth guide to getting started!

## Setup

Since NestJS is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

<project>/moon.yml

```yaml
layer: 'application'

fileGroups:
  app:
    - 'nest-cli.*'

tasks:
  dev:
    command: 'nest start --watch'
    local: true
  build:
    command: 'nest build'
    inputs:
      - '@group(app)'
      - '@group(sources)'
```

### TypeScript integration

NestJS has [built-in support for TypeScript](https://NestJS.io/guide/typescript-configuration), so there is no need for additional configuration to enable TypeScript support.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository.

## Configuration

### Root-level

We suggest *against* root-level configuration, as NestJS should be installed per-project, and the `nest` command expects the configuration to live relative to the project root.

### Project-level

When creating a new NestJS project, a [`nest-cli.json`](https://docs.nestjs.com/cli/monorepo) is created, and *must* exist in the project root. This allows each project to configure NestJS for their needs.

<project>/nest-cli.json

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "type": "application",
  "root": "./",
  "sourceRoot": "src",
  "compilerOptions": {
    "tsConfigPath": "tsconfig.build.json"
  }
}
```


## See Also

- [`moon.yml`](/docs/config/project)
- [global `typecheck` task](/docs/guides/examples/typescript)
