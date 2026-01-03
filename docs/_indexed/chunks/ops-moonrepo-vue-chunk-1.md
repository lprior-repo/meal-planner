---
doc_id: ops/moonrepo/vue
chunk_id: ops/moonrepo/vue#chunk-1
heading_path: ["Vue example"]
chunk_type: prose
tokens: 162
summary: "Vue example"
---

# Vue example

> **Context**: Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of thi

Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of this, moon has no guidelines around utilizing Vue directly. You can use Vue however you wish!

However, with that being said, Vue is typically coupled with [Vite](https://vitejs.dev/). To scaffold a new Vue project with Vite, run the following command in a project root.

```
npm init vue@latest
```

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite) for a more holistic view.
