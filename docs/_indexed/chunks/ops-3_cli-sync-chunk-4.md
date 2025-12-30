---
doc_id: ops/3_cli/sync
chunk_id: ops/3_cli/sync#chunk-4
heading_path: ["Sync", "Push API"]
chunk_type: prose
tokens: 539
summary: "Push API"
---

## Push API

The `wmill sync push` command is used to push local changes and apply them remotely. It synchronizes the remote workspace with the local workspace by uploading any local changes and updating the corresponding remote files.

```bash
wmill sync push [options]
```

### Options

| Option                 | Parameter     | Description                                                                                                                                                                                         |
| ---------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-h, --help`           | None          | Show help options.                                                                                                                                                                                  |
| `--workspace`          | `<workspace>` | Specify the target workspace. This overrides the default workspace.                                                                                                                                 |
| `--debug`, `--verbose` | None          | Show debug/verbose logs.                                                                                                                                                                            |
| `--show-diffs`         | None          | Show diff information when syncing (may show sensitive information).                                                                                                                                |
| `--token`              | `<token>`     | Specify an API token. This will override any stored token.                                                                                                                                          |
| `--base-url`           | `<baseUrl>`   | Specify the base URL of the API. If used, `--token` and `--workspace` are required and no local remote/workspace will be used.                                                                      |
| `--yes`                | None          | Push without needing confirmation.                                                                                                                                                                  |
| `--plain-secrets`      | None          | Push secrets as plain text.                                                                                                                                                                         |
| `--json`               | None          | Use JSON instead of YAML.                                                                                                                                                                           |
| `--skip-variables`     | None          | Skip syncing variables (including secrets).                                                                                                                                                         |
| `--skip-secrets`       | None          | Skip syncing only secret variables.                                                                                                                                                                 |
| `--skip-resources`     | None          | Skip syncing resources.                                                                                                                                                                             |
| `--include-schedules`  | None          | Include syncing schedules.                                                                                                                                                                          |
| `--include-users`      | None          | Include syncing users.                                                                                                                                                                              |
| `--include-groups`     | None          | Include syncing groups.                                                                                                                                                                             |
| `--include-triggers`   | None          | Include syncing triggers (HTTP routes, WebSocket, Postgres, Kafka, NATS, SQS, GCP Pub/Sub, MQTT).                                                                                                   |
| `--include-settings`   | None          | Include syncing workspace settings.                                                                                                                                                                 |
| `--include-key`        | None          | Include workspace encryption key.                                                                                                                                                                   |
| `--skip-branch-validation` | None      | Skip git branch validation and prompts. Useful for temporary feature branches that don't need to be added to wmill.yaml.                                                                            |
| `-i, --includes`       | `<patterns>`  | Comma-separated patterns to specify which files to take into account (among files compatible with Windmill). Patterns can include `*` (any string until '/') and `**` (any string).                 |
| `-e, --excludes`       | `<patterns>`  | Comma-separated patterns to specify which files to NOT take into account.                                                                                                                           |
| `--extra-includes`     | `<patterns>`  | Comma-separated patterns to specify which files to take into account (among files compatible with Windmill). Useful to still take `wmill.yaml` into account and act as a second pattern to satisfy. |
| `--message`            | `<message>`   | Include a message that will be added to all scripts/flows/apps updated during this push.                                                                                                            |
