---
doc_id: concept/windmill/app
chunk_id: concept/windmill/app#chunk-3
heading_path: ["Apps", "Pushing an app"]
chunk_type: code
tokens: 83
summary: "Pushing an app"
---

## Pushing an app

Pushing an app to a Windmill instance is done using the `wmill app push` command.

```bash
wmill app push <file_path>
```text

### Arguments

| Argument    | Description                       |
| ----------- | --------------------------------- |
| `file_path` | The path to the app file to push. |

### Examples

1. Push the app located at `./my_app.json`.

```bash
wmill app push ./my_app.json
```text
