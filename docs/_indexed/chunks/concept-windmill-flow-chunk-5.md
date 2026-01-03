---
doc_id: concept/windmill/flow
chunk_id: concept/windmill/flow#chunk-5
heading_path: ["Flows", "Running a flow"]
chunk_type: prose
tokens: 169
summary: "Running a flow"
---

## Running a flow

Running a flow by its path s done using the `wmill flow run` command.

```bash
wmill flow run <remote_path> [options]
```text

### Arguments

| Argument      | Description                     |
| ------------- | ------------------------------- |
| `remote_path` | The path of the flow to be run. |

### Options

| Option         | Parameters | Description                                                                   |
| -------------- | ---------- | ----------------------------------------------------------------------------- |
| `-d, --data`   | `data`     | Inputs specified as a JSON string or a file using @filename or stdin using @- . Resources and variables must be passed using "$res:..." or "$var:..." For example `wmill flow run u/henri/message_to_slack -d '{"slack":"$res:u/henri/henri_slack_perso","channel":"general","text":"hello dear team"}'` |
| `-s, --silent` |            | Do not ouput anything other then the final output. Useful for scripting.      |

![CLI arguments](../../assets/cli/cli_arguments.png "CLI arguments")
