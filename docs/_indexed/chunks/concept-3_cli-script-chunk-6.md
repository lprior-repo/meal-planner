---
doc_id: concept/3_cli/script
chunk_id: concept/3_cli/script#chunk-6
heading_path: ["Scripts", "Showing a script"]
chunk_type: code
tokens: 92
summary: "Showing a script"
---

## Showing a script

The wmill script show command is used to show the contents of a script on the remote server.

```bash
wmill script show <path>
```

### Arguments

| Argument | Description                                                |
| -------- | ---------------------------------------------------------- |
| `path`   | The path to the remote script file that needs to be shown. |

### Examples

1. Show the script located at `f/scripts/test`

```bash
wmill script show f/scripts/test
```
