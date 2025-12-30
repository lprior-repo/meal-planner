---
doc_id: concept/3_cli/flow
chunk_id: concept/3_cli/flow#chunk-4
heading_path: ["Flows", "Creating a new flow"]
chunk_type: code
tokens: 85
summary: "Creating a new flow"
---

## Creating a new flow

The wmill flow bootstrap command is used to create a new flow locally.

```bash
wmill flow bootstrap [--summary <summary>] [--description <description>] <path>
```text

### Arguments

| Argument   | Description                          |
| ---------- | ------------------------------------ |
| `path`     | The path of the flow to be created.  |

### Examples

1. Create a new flow `f/flows/flashy_flow`

```bash
wmill flow bootstrap f/flows/flashy_flow
```text
