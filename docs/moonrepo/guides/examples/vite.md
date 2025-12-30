# Vite & Vitest example

In this guide, you'll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.

Begin by creating a new Vite project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
yarn create vite
```

If you plan on using Vitest, run the following command to add the `vitest` dependency to a project, otherwise skip to the setup section.

```
yarn workspace <project> add --dev vitest
```

## Setup

Since Vite is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

tip

We suggest inheriting Vite tasks from the [official moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/vite).

<project>/moon.yml

```yaml
# Inherit tasks from the `vite` and `vitest` presets
# https://github.com/moonrepo/moon-configs
tags: ['vite', 'vitest']
```

## Configuration

### Root-level

We suggest *against* root-level configuration, as Vite should be installed per-project, and the `vite` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Vite project, a [`vite.config.<js|ts>`](https://vitejs.dev/config) is created, and *must* exist in the project root.

<project>/vite.config.js

```js
import { defineConfig } from 'vite';

export default defineConfig({
  // ...
  build: {
    // These must be `outputs` in the `build` task
    outDir: 'dist',
  },
  test: {
    // Vitest settings
  },
});
```

> If you'd prefer to configure Vitest in a [separate configuration file](https://vitest.dev/guide/#configuring-vitest), create a `vitest.config.<js|ts>` file.
