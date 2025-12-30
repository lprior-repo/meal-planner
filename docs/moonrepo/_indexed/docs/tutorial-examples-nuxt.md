---
id: tutorial/examples/nuxt
title: "Nuxt example"
category: tutorial
tags: ["tutorial", "examples", "nuxt", "beginner"]
---

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
