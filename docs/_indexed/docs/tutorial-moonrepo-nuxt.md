---
id: tutorial/moonrepo/nuxt
title: "Nuxt example"
category: tutorial
tags: ["tutorial", "nuxt", "beginner", "moonrepo"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Nuxt example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.</description>
  <created_at>2026-01-02T19:55:27.099708</created_at>
  <updated_at>2026-01-02T19:55:27.099708</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Testing" level="2"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>testing</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/guides/examples/jest</entity>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>tutorial,nuxt,beginner,moonrepo</tags>
</doc_metadata>
-->

# Nuxt example

> **Context**: In this guide, you'll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.

In this guide, you'll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.

Begin by creating a new Nuxt project at a specified folder path (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx nuxi init <project>
```

> View the [official Nuxt docs](https://nuxt.com/docs/getting-started/installation) for a more in-depth guide to getting started!

## Setup

Since Nuxt is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

<project>/moon.yml

```yaml
fileGroups:
  nuxt:
    - 'assets/**/*'
    - 'components/**/*'
    - 'composables/**/*'
    - 'content/**/*'
    - 'layouts/**/*'
    - 'middleware/**/*'
    - 'pages/**/*'
    - 'plugins/**/*'
    - 'public/**/*'
    - 'server/**/*'
    - 'utils/**/*'
    - '.nuxtignore'
    - 'app.config.*'
    - 'app.vue'
    - 'nuxt.config.*'

tasks:
  nuxt:
    command: 'nuxt'
    local: true

  # Production build
  build:
    command: 'nuxt build'
    inputs:
      - '@group(nuxt)'
    outputs:
      - '.nuxt'
      - '.output'

  # Development server
  dev:
    command: 'nuxt dev'
    local: true

  # Preview production build locally
  preview:
    command: 'nuxt preview'
    deps:
      - '~:build'
    local: true
```

Be sure to keep the `postinstall` script in your project's `package.json`.

<project>/package.json

```json
{
  // ...
  "scripts": {
    "postinstall": "nuxt prepare"
  }
}
```

### ESLint integration

Refer to our [Vue documentation](/docs/guides/examples/vue#eslint-integration) for more information on linting.

### TypeScript integration

Nuxt requires `vue-tsc` for typechecking, so refer to our [Vue documentation](/docs/guides/examples/vue#typescript-integration) for more information.

## Configuration

### Root-level

We suggest *against* root-level configuration, as Nuxt should be installed per-project, and the `nuxt` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Nuxt project, a [`nuxt.config.ts`](https://v3.nuxtjs.org/api/configuration/nuxt-config) is created, and *must* exist in the project root. This allows each project to configure Next.js for their needs.

<project>/nuxt.config.ts

```ts
export default defineNuxtConfig({});
```

## Testing

Nuxt supports testing through [Jest](https://jestjs.io/) or [Vitest](https://vitest.dev/). Refer to our [Jest documentation](/docs/guides/examples/jest) or [Vitest documentation](/docs/guides/examples/vite) for more information on testing.


## See Also

- [Vue](/docs/guides/examples/vue)
- [`moon.yml`](/docs/config/project)
- [Vue documentation](/docs/guides/examples/vue#eslint-integration)
- [Vue documentation](/docs/guides/examples/vue#typescript-integration)
- [Jest documentation](/docs/guides/examples/jest)
