---
doc_id: ops/moonrepo/sveltekit
chunk_id: ops/moonrepo/sveltekit#chunk-2
heading_path: ["SvelteKit example", "Setup"]
chunk_type: prose
tokens: 41
summary: "Setup"
---

## Setup

Since SvelteKit is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

tip

We suggest inheriting SvelteKit tasks from the [official moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/sveltekit).

<project>/moon.yml

```yaml
