---
doc_id: ops/examples/vite
chunk_id: ops/examples/vite#chunk-2
heading_path: ["Vite & Vitest example", "Setup"]
chunk_type: prose
tokens: 41
summary: "Setup"
---

## Setup

Since Vite is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

tip

We suggest inheriting Vite tasks from the [official moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/vite).

<project>/moon.yml

```yaml
