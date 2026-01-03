---
doc_id: tutorial/moonrepo/nuxt
chunk_id: tutorial/moonrepo/nuxt#chunk-3
heading_path: ["Nuxt example", "Configuration"]
chunk_type: prose
tokens: 83
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as Nuxt should be installed per-project, and the `nuxt` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Nuxt project, a [`nuxt.config.ts`](https://v3.nuxtjs.org/api/configuration/nuxt-config) is created, and *must* exist in the project root. This allows each project to configure Next.js for their needs.

<project>/nuxt.config.ts

```ts
export default defineNuxtConfig({});
```
