---
doc_id: tutorial/examples/remix
chunk_id: tutorial/examples/remix#chunk-1
heading_path: ["Remix example"]
chunk_type: prose
tokens: 143
summary: "Remix example"
---

# Remix example

> **Context**: In this guide, you'll learn how to integrate [Remix](https://remix.run) into moon.

In this guide, you'll learn how to integrate [Remix](https://remix.run) into moon.

Begin by creating a new Remix project at a specified folder path (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx create-remix
```

During this installation, Remix will ask a handful of questions, but be sure to answer "No" for the "Do you want me to run `npm install`?" question. We suggest installing dependencies at the workspace root via package workspaces!

> View the [official Remix docs](https://remix.run/docs/en/v1) for a more in-depth guide to getting started!
