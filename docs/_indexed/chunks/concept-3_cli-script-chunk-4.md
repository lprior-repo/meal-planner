---
doc_id: concept/3_cli/script
chunk_id: concept/3_cli/script#chunk-4
heading_path: ["Scripts", "Creating a new script"]
chunk_type: code
tokens: 170
summary: "Creating a new script"
---

## Creating a new script

The wmill script bootstrap command is used to create a new script locally in the desired language.

```bash
wmill script bootstrap [--summary <summary>] [--description <description>] <path> <language>
```

### Arguments

| Argument   | Description                                                                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `path`     | The path of the script to be created.                                                                                                                                                    |
| `language` | The language of the new script. It should be one of `deno`, `python3`, `bun`, `bash`, `go`, `nativets`, `postgresql`, `mysql`, `bigquery`, `snowflake`, `mysql`, `graphql`, `powershell` |

### Examples

1. Create a new python script `f/scripts/hallowed_script`

```bash
wmill script bootstrap f/scripts/hallowed_script python3
```

2. Create a new deno script `f/scripts/auspicious_script` with a summary and a description

```bash
wmill script bootstrap --summary 'Great script' --description 'This script does this and that' f/scripts/auspicious_script deno
```
