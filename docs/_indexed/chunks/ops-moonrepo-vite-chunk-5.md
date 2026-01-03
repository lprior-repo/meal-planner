---
doc_id: ops/moonrepo/vite
chunk_id: ops/moonrepo/vite#chunk-5
heading_path: ["Vite & Vitest example", "Configuration"]
chunk_type: prose
tokens: 128
summary: "Configuration"
---

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
