---
doc_id: ops/examples/sveltekit
chunk_id: ops/examples/sveltekit#chunk-5
heading_path: ["SvelteKit example", "Configuration"]
chunk_type: prose
tokens: 128
summary: "Configuration"
---

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
