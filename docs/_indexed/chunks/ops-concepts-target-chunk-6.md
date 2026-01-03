---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-6
heading_path: ["Targets", "Run `lint` in all projects"]
chunk_type: prose
tokens: 61
summary: "Run `lint` in all projects"
---

## Run `lint` in all projects
$ moon run :lint
```

### Closest project `~` (v1.33.0)

If you are within a project folder, or an arbitrarily nested folder, and want to run a task in the closest project (traversing upwards), the `~` scope can be used.

```bash
