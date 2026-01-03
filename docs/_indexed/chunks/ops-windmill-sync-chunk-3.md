---
doc_id: ops/windmill/sync
chunk_id: ops/windmill/sync#chunk-3
heading_path: ["Sync", "Pull API"]
chunk_type: prose
tokens: 552
summary: "Pull API"
---

## Pull API

The `wmill sync pull` command is used to pull remote changes and apply them locally. It synchronizes the local workspace with the remote workspace by downloading any remote changes and updating the corresponding local files.

```bash
wmill sync pull [options]
```

### Options

| Option                 | Parameter     | Description                                                                                                                                                                                                          |
| ---------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-h, --help`           | None          | Show help options.                                                                                                                                                                                                   |
| `--yes`                | None          | Pull without needing confirmation. The command proceeds automatically without user intervention.                                                                                                                     |
| `--plain-secrets`      | None          | Pull secrets as plain text. Secrets are downloaded without encryption or obfuscation.                                                                                                                                |
| `--json`               | None          | Use JSON instead of YAML. The downloaded files are in JSON format instead of YAML.                                                                                                                                   |
| `--workspace`          | `<workspace>` | Specify the target workspace. This overrides the default workspace.                                                                                                                                                  |
| `--debug`, `--verbose` | None          | Show debug/verbose logs.                                                                                                                                                                                             |
| `--show-diffs`         | None          | Show diff information when syncing (may show sensitive information).                                                                                                                                                 |
| `--token`              | `<token>`     | Specify an API token. This will override any stored token.                                                                                                                                                           |
| `--base-url`           | `<baseUrl>`   | Specify the base URL of the API. If used, `--token` and `--workspace` are required and no local remote/workspace will be used.                                                                                       |
| `--skip-variables`     | None          | Skip syncing variables (including secrets).                                                                                                                                                                          |
| `--skip-secrets`       | None          | Skip syncing only secret variables.                                                                                                                                                                                  |
| `--skip-resources`     | None          | Skip syncing resources.                                                                                                                                                                                              |
| `--include-schedules`  | None          | Include syncing schedules.                                                                                                                                                                                           |
| `--include-users`      | None          | Include syncing users.                                                                                                                                                                                               |
| `--include-groups`     | None          | Include syncing groups.                                                                                                                                                                                              |
| `--include-triggers`   | None          | Include syncing triggers (HTTP routes, WebSocket, Postgres, Kafka, NATS, SQS, GCP Pub/Sub, MQTT).                                                                                                                    |
| `--include-settings`   | None          | Include syncing workspace settings.                                                                                                                                                                                  |
| `--include-key`        | None          | Include workspace encryption key.                                                                                                                                                                                    |
| `--skip-branch-validation` | None      | Skip git branch validation and prompts. Useful for temporary feature branches that don't need to be added to wmill.yaml.                                                                                             |
| `-i, --includes`       | `<patterns>`  | Comma-separated patterns to specify which files to take into account (among files compatible with Windmill). Overrides `wmill.yaml` includes. Patterns can include `*` (any string until '/') and `**` (any string). |
| `-e, --excludes`       | `<patterns>`  | Comma-separated patterns to specify which files to NOT take into account. Overrides `wmill.yaml` excludes.                                                                                                           |
| `--extra-includes`     | `<patterns>`  | Comma-separated patterns to specify which files to take into account (among files compatible with Windmill). Useful to still take `wmill.yaml` into account and act as a second pattern to satisfy.                  |
