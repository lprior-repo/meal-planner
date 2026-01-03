---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-5
heading_path: ["Targets", "Run scopes"]
chunk_type: prose
tokens: 74
summary: "Run scopes"
---

## Run scopes

These scopes are only available on the command line when running tasks with `moon run` or `moon ci`.

### All projects

For situations where you want to run a specific target in *all* projects, for example `lint`ing, you can utilize the all projects scope by omitting the project name from the target: `:lint`.

```bash
