---
doc_id: concept/3_cli/script
chunk_id: concept/3_cli/script#chunk-7
heading_path: ["Scripts", "Running a script"]
chunk_type: prose
tokens: 169
summary: "Running a script"
---

## Running a script

Running a script by its path s done using the `wmill script run` command.

```bash
wmill script run <remote_path> [options]
```text

### Arguments

| Argument      | Description                       |
| ------------- | --------------------------------- |
| `remote_path` | The path of the script to be run. |

### Options

| Option         | Parameters | Description                                                                                                                                                                                                                                                                                                |
| -------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-d, --data`   | `data`     | Inputs specified as a JSON string or a file using @filename or stdin using @- . Resources and variables must be passed using "$res:..." or "$var:..." For example `wmill script run u/henri/message_to_slack -d '{"slack":"$res:u/henri/henri_slack_perso","channel":"general","text":"hello dear team"}'` |
| `-s, --silent` |            | Do not ouput anything other then the final output. Useful for scripting.                                                                                                                                                                                                                                   |

![CLI arguments](../../assets/cli/cli_arguments.png 'CLI arguments')
