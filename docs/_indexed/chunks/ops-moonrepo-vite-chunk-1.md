---
doc_id: ops/moonrepo/vite
chunk_id: ops/moonrepo/vite#chunk-1
heading_path: ["Vite & Vitest example"]
chunk_type: code
tokens: 126
summary: "Vite & Vitest example"
---

# Vite & Vitest example

> **Context**: In this guide, you'll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.

In this guide, you'll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.

Begin by creating a new Vite project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
yarn create vite
```

If you plan on using Vitest, run the following command to add the `vitest` dependency to a project, otherwise skip to the setup section.

```
yarn workspace <project> add --dev vitest
```
