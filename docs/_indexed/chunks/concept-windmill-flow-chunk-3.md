---
doc_id: concept/windmill/flow
chunk_id: concept/windmill/flow#chunk-3
heading_path: ["Flows", "Pushing a flow"]
chunk_type: code
tokens: 110
summary: "Pushing a flow"
---

## Pushing a flow

Pushing a flow to a Windmill instance is done using the `wmill flow push` command.

```bash
wmill flow push <file_path> <remote_path>
```text

### Arguments

| Argument      | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `file_path`   | The path to the flow file to push.                             |
| `remote_path` | The remote path where the flow specification should be pushed. |

### Examples

1. Push the flow located at `path/to/local/flow.yaml` to the remote path `f/flows/test`.

```bash
wmill flow push path/to/local/flow.yaml f/flows/test
```text
