---
doc_id: ops/3_cli/gitsync-settings
chunk_id: ops/3_cli/gitsync-settings#chunk-3
heading_path: ["Git sync settings", "Push API"]
chunk_type: prose
tokens: 327
summary: "Push API"
---

## Push API

The `wmill gitsync-settings push` command is used to push local git-sync settings and apply them to the remote workspace configuration. It synchronizes the workspace git-sync settings with your local `wmill.yaml`.

```bash
wmill gitsync-settings push [options]
```

### Options

| Option                        | Parameter             | Description                                                                                                                                                                                         |
| ----------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-h, --help`                  | None                  | Show help options.                                                                                                                                                                                  |
| `--repository`                | `<repository>`        | Specify repository path (e.g., u/user/repo). If not specified, will auto-select if only one repository exists or prompt for selection.                                                             |
| `--diff`                      | None                  | Show what would be pushed without applying changes. Preview the modifications that would be made to the workspace configuration.                                                                   |
| `--json-output`               | None                  | Output in JSON format. Useful for scripting and automation.                                                                                                                                        |
| `--with-backend-settings`     | `<json>`              | Use provided JSON settings instead of querying backend (primarily for testing purposes).                                                                                                           |
| `--yes`                       | None                  | Skip interactive prompts and use default behavior. The command proceeds automatically without user intervention.                                                                                    |
| `--promotion`                 | `<branch>`            | Use promotionOverrides from the specified branch instead of regular overrides.                                                                                                                     |
| `--workspace`                 | `<workspace>`         | Specify the target workspace. This overrides the default workspace.                                                                                                                                 |
| `--debug`, `--verbose`        | None                  | Show debug/verbose logs.                                                                                                                                                                            |
| `--token`                     | `<token>`             | Specify an API token. This will override any stored token.                                                                                                                                          |
| `--base-url`                  | `<baseUrl>`           | Specify the base URL of the API. If used, `--token` and `--workspace` are required and no local remote/workspace will be used.                                                                     |
