---
id: ops/moonrepo/sveltekit
title: "SvelteKit example"
category: ops
tags: ["sveltekit", "advanced", "operations", "javascript", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>SvelteKit example</title>
  <description>[SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly concise components that do minimal work in the browser</description>
  <created_at>2026-01-02T19:55:27.111400</created_at>
  <updated_at>2026-01-02T19:55:27.111400</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>js_config</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/prettier</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>sveltekit,advanced,operations,javascript,moonrepo</tags>
</doc_metadata>
-->

# SvelteKit example

> **Context**: [SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly conc

[SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly concise components that do minimal work in the browser, using languages you already know — HTML, CSS and JavaScript. It's a love letter to web development.

```
cd apps && npm create svelte@latest <project>
```

You will be prompted to choose between select templates, TypeScript, ESLint, Prettier, Playwright and Vitest among other options. moon supports and has guides for many of these tools.

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite), [using ESLint with moon](/docs/guides/examples/eslint) and [using Prettier with moon](/docs/guides/examples/prettier) for a more holistic view.

## Setup

Since SvelteKit is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

tip

We suggest inheriting SvelteKit tasks from the [official moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/sveltekit).

<project>/moon.yml

```yaml
## Inherit tasks from the `sveltekit` preset
## https://github.com/moonrepo/moon-configs
tags: ['sveltekit']
```

### ESLint integration

SvelteKit provides an option to setup ESLint along with your project, with moon you can use a [global `lint` task](/docs/guides/examples/eslint). We encourage using the global `lint` task for consistency across all projects within the repository. With this approach, the `eslint` command itself will be ran and the `svelte3` rules will still be used.

<project>/moon.yml

```yaml
tasks:
  # Extends the top-level lint
  lint:
    args:
      - '--ext'
      - '.ts,.svelte'
```

Be sure to enable the Svelte parser and plugin in a project local ESLint configuration file.

.eslintrc.cjs

```js
module.exports = {
  plugins: ['svelte3'],
  ignorePatterns: ['*.cjs'],
  settings: {
    'svelte3/typescript': () => require('typescript'),
  },
  overrides: [{ files: ['*.svelte'], processor: 'svelte3/svelte3' }],
};
```

### TypeScript integration

SvelteKit also has built-in support for TypeScript, but has similar caveats to the [ESLint integration](#eslint-integration). TypeScript itself is a bit involved, so we suggest reading the official [SvelteKit documentation](https://kit.svelte.dev/docs/introduction) before continuing.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository. However, because Svelte isn't standard JavaScript, it requires the use of the `svelte-check` command for type-checking.

info

The [moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/sveltekit) provides the `check` task below.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['typecheck']

tasks:
  check:
    command: 'svelte-check --tsconfig ./tsconfig.json'
    deps:
      - 'typecheck-sync'
    inputs:
      - '@group(svelte)'
      - 'tsconfig.json'
```

In case Svelte doesn't automatically create a `tsconfig.json`, you can use the following:

<project>/tsconfig.json

```json
{
  "extends": "./.svelte-kit/tsconfig.json",
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "sourceMap": true,
    "strict": true
  }
}
```

## Configuration

### Root-level

We suggest *against* root-level configuration, as SvelteKit should be installed per-project, and the `vite` command expects the configuration to live relative to the project root.

### Project-level

When creating a new SvelteKit project, a [`svelte.config.js`](https://kit.svelte.dev/docs/configuration) is created, and *must* exist in the project root. This allows each project to configure SvelteKit for their needs.

<project>/svelte.config.js

```js
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/kit/vite';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://kit.svelte.dev/docs/integrations#preprocessors
  // for more information about preprocessors
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter(),
  },
};

export default config;
```


## See Also

- [using Vite (and Vitest) with moon](/docs/guides/examples/vite)
- [using ESLint with moon](/docs/guides/examples/eslint)
- [using Prettier with moon](/docs/guides/examples/prettier)
- [`moon.yml`](/docs/config/project)
- [global `lint` task](/docs/guides/examples/eslint)
