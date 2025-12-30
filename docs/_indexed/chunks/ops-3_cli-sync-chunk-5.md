---
doc_id: ops/3_cli/sync
chunk_id: ops/3_cli/sync#chunk-5
heading_path: ["Sync", "wmill.yaml"]
chunk_type: prose
tokens: 53
summary: "wmill.yaml"
---

## wmill.yaml

Note that you can set the default TypeScript language and explicitly exclude (or include) specific files or folders to be taken into account with a [`wmill.yaml` file](https://github.com/windmill-labs/windmill-sync-example/blob/main/wmill.yaml).

### Basic configuration

```yaml
defaultTs: bun  # TypeScript runtime: 'bun' or 'deno'
