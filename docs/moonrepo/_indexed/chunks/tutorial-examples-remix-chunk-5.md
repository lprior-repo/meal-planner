---
doc_id: tutorial/examples/remix
chunk_id: tutorial/examples/remix#chunk-5
heading_path: ["Remix example", "Configuration"]
chunk_type: prose
tokens: 87
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as Remix should be installed per-project, and the `remix` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Remix project, a [`remix.config.js`](https://remix.run/docs/en/v1/api/conventions) is created, and *must* exist in the project root. This allows each project to configure Remix for their needs.

<project>/remix.config.js

```js
module.exports = {
  appDirectory: 'app',
};
```
