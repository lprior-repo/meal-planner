---
doc_id: ops/examples/solid
chunk_id: ops/examples/solid#chunk-2
heading_path: ["Solid example", "Setup"]
chunk_type: code
tokens: 184
summary: "Setup"
---

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
