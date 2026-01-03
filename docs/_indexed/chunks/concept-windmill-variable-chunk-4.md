---
doc_id: concept/windmill/variable
chunk_id: concept/windmill/variable#chunk-4
heading_path: ["Variables", "Pushing a variable"]
chunk_type: prose
tokens: 136
summary: "Pushing a variable"
---

## Pushing a variable

The cli push command allows you to push a local variable spec to the remote workspace, overriding any existing remote versions.

```bash
wmill push <file_path:string> <remote_path:string> [--plain-secrets]
```text

### Arguments

| Argument      | Description                                       |
| ------------- | ------------------------------------------------- |
| `file_path`   | The path to the variable file to push.            |
| `remote_path` | The path of the variable in the remote workspace. |

### Options

| Option            | Description                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `--plain-secrets` | (Optional) Specifies whether to push secrets as plain text. If provided, secrets will not be encrypted in the remote workspace. |
