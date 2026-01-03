---
doc_id: ops/moonrepo/astro
chunk_id: ops/moonrepo/astro#chunk-6
heading_path: ["Astro example", "Configuration"]
chunk_type: prose
tokens: 93
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as Astro should be installed per-project, and the `astro` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Astro project, a [`astro.config.mjs`](https://docs.astro.build/en/reference/configuration-reference/) is created, and *must* exist in the project root. This allows each project to configure Astro for their needs.

<project>/astro.config.mjs

```js
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({});
```
