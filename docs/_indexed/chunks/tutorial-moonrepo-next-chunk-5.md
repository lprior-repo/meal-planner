---
doc_id: tutorial/moonrepo/next
chunk_id: tutorial/moonrepo/next#chunk-5
heading_path: ["Next example", "Configuration"]
chunk_type: prose
tokens: 87
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as Next.js should be installed per-project, and the `next` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Next.js project, a [`next.config.<js|mjs>`](https://nextjs.org/docs/api-reference/next.config.js/introduction) is created, and *must* exist in the project root. This allows each project to configure Next.js for their needs.

<project>/next.config.js

```js
module.exports = {
  compress: true,
};
```
