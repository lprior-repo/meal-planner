---
id: ops/moonrepo/solid
title: "Solid example"
category: ops
tags: ["javascript", "solid", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Solid example</title>
  <description>[Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid is an application or library concern, and not a bui</description>
  <created_at>2026-01-02T19:55:27.107413</created_at>
  <updated_at>2026-01-02T19:55:27.107413</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Vite integration" level="3"/>
  </sections>
  <features>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
    <feature>vite_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/tags/solid</entity>
    <entity relationship="uses">/docs/tags/solidjs</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>javascript,solid,operations,moonrepo</tags>
</doc_metadata>
-->

# Solid example

> **Context**: [Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid i

[Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid is an application or library concern, and not a build system one, since the bundling of Solid is abstracted away through the application or a bundler.

With that being said, we do have some suggestions on utilizing Solid effectively in a monorepo. To begin, install Solid to a project.

```
yarn workspace <project> add solid-js
```

## Setup

Solid utilizes JSX for rendering markup, which requires [`babel-preset-solid`](https://www.npmjs.com/package/babel-preset-solid) for parsing and transforming. To enable the preset for the entire monorepo, add the preset to a root `babel.config.js`, otherwise add it to a `.babelrc.js` in each project that requires it.

```js
module.exports = {
  presets: ['solid'],
};
```

### TypeScript integration

For each project using Solid, add the following compiler options to the `tsconfig.json` found in the project root.

<project>/tsconfig.json

```json
{
  "compilerOptions": {
    "jsx": "preserve",
    "jsxImportSource": "solid-js"
  }
}
```

### Vite integration

If you're using a [Vite](/docs/guides/examples/vite) powered application (Solid Start or starter templates), you should enable [`vite-plugin-solid`](https://www.npmjs.com/package/vite-plugin-solid) instead of configuring Babel. Be sure to read our [guide on Vite](/docs/guides/examples/vite) as well!

<project>/vite.config.js

```js
import { defineConfig } from 'vite';
import solidPlugin from 'vite-plugin-solid';

export default defineConfig({
  // ...
  plugins: [solidPlugin()],
});
```

**Tags:**

- [solid](/docs/tags/solid)
- [solidjs](/docs/tags/solidjs)


## See Also

- [Vite](/docs/guides/examples/vite)
- [guide on Vite](/docs/guides/examples/vite)
- [solid](/docs/tags/solid)
- [solidjs](/docs/tags/solidjs)
