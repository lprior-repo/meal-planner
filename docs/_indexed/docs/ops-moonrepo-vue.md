---
id: ops/moonrepo/vue
title: "Vue example"
category: ops
tags: ["vue", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Vue example</title>
  <description>Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of this, moon has no guidelines around utilizing Vue dir</description>
  <created_at>2026-01-02T19:55:27.123051</created_at>
  <updated_at>2026-01-02T19:55:27.123051</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
  </sections>
  <features>
    <feature>eslint_integration</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>vue,operations,moonrepo</tags>
</doc_metadata>
-->

# Vue example

> **Context**: Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of thi

Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of this, moon has no guidelines around utilizing Vue directly. You can use Vue however you wish!

However, with that being said, Vue is typically coupled with [Vite](https://vitejs.dev/). To scaffold a new Vue project with Vite, run the following command in a project root.

```
npm init vue@latest
```

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite) for a more holistic view.

## Setup

This section assumes Vue is being used with Vite.

### ESLint integration

When linting with [ESLint](/docs/guides/examples/eslint) and the [`eslint-plugin-vue`](https://eslint.vuejs.org/user-guide/#installation) library, you'll need to include the `.vue` extension within the `lint` task. This can be done by extending the top-level task within the project (below), or by adding it to the top-level entirely.

<project>/moon.yml

```yaml
tasks:
  lint:
    args:
      - '--ext'
      - '.js,.ts,.vue'
```

Furthermore, when using TypeScript within ESLint, we need to make a few additional changes to the `.eslintrc.js` config found in the root (if the entire repo is Vue), or within the project (if only the project is Vue).

```js
module.exports = {
  parser: 'vue-eslint-parser',
  parserOptions: {
    extraFileExtensions: ['.vue'],
    parser: '@typescript-eslint/parser',
    project: 'tsconfig.json', // Or another config
    tsconfigRootDir: __dirname,
  },
};
```

### TypeScript integration

Vue does not use [TypeScript](/docs/guides/examples/typescript)'s `tsc` binary directly, but instead uses [`vue-tsc`](https://vuejs.org/guide/typescript/overview.html), which is a thin wrapper around `tsc` to support Vue components. Because of this, we should update the `typecheck` task in the project to utilize this command instead.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['typecheck']

tasks:
  typecheck:
    command:
      - 'vue-tsc'
      - '--noEmit'
      # Always use pretty output
      - '--pretty'
    inputs:
      - 'env.d.ts'
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Project configs
      - 'tsconfig.json'
      - 'tsconfig.*.json'
      # Root configs (extended from only)
      - '/tsconfig.options.json'
```

> Be sure `tsconfig.json` compiler options are based on [`@vue/tsconfig`](https://vuejs.org/guide/typescript/overview.html#configuring-tsconfig-json).


## See Also

- [using Vite (and Vitest) with moon](/docs/guides/examples/vite)
- [ESLint](/docs/guides/examples/eslint)
- [TypeScript](/docs/guides/examples/typescript)
