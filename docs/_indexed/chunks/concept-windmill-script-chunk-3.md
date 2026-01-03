---
doc_id: concept/windmill/script
chunk_id: concept/windmill/script#chunk-3
heading_path: ["Scripts", "Pushing a script"]
chunk_type: code
tokens: 130
summary: "Pushing a script"
---

## Pushing a script

The wmill script push command is used to push a local script to the remote server, overriding any existing remote versions of the script. This command allows you to manage and synchronize your scripts across different environments.

This command support .ts, .js, .py, .go and .sh files.

```bash
wmill script push <path>
```text

### Arguments

| Argument | Description                                                |
| -------- | ---------------------------------------------------------- |
| `path`   | The path to the local script file that needs to be pushed. |

### Examples

1. Push the script located at `/path/to/script.js`

```bash
wmill script push /path/to/script.js
```text
