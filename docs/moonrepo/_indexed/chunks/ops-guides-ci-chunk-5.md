---
doc_id: ops/guides/ci
chunk_id: ops/guides/ci#chunk-5
heading_path: ["Continuous integration (CI)", "Choosing targets (v1.14.0)"]
chunk_type: prose
tokens: 115
summary: "Choosing targets (v1.14.0)"
---

## Choosing targets (v1.14.0)

By default `moon ci` will run *all* tasks from *all* projects that are affected by touched files and have the [`runInCI`](/docs/config/project#runinci) task option enabled. This is a great catch-all solution, but may not vibe with your workflow or requirements.

If you'd prefer more control, you can pass a list of targets to `moon ci`, instead of moon attempting to detect them. When providing targets, `moon ci` will still only run them if affected by touched files, but will still filter with the `runInCI` option.

```shell
