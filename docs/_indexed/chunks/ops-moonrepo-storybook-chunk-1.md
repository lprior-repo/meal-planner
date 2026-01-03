---
doc_id: ops/moonrepo/storybook
chunk_id: ops/moonrepo/storybook#chunk-1
heading_path: ["Storybook example"]
chunk_type: prose
tokens: 171
summary: "Storybook example"
---

# Storybook example

> **Context**: Storybook is a frontend workshop for building UI components and pages in isolation. Thousands of teams use it for UI development, testing, and documen

Storybook is a frontend workshop for building UI components and pages in isolation. Thousands of teams use it for UI development, testing, and documentation. It's open source and free.

[Storybook v7](https://storybook.js.org/docs/7.0) is typically coupled with [Vite](https://vitejs.dev/). To scaffold a new Storybook project with Vite, run the following command in a project root. This guide assumes you are using React, however it is possible to use almost any (meta) framework with Storybook.

```
cd <project> && npx storybook init
```

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite) and [using Jest with moon](/docs/guides/examples/jest) for a more holistic view.
