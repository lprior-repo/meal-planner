---
doc_id: ops/windmill/gitsync-settings
chunk_id: ops/windmill/gitsync-settings#chunk-2
heading_path: ["Git sync settings", "Pull API"]
chunk_type: prose
tokens: 382
summary: "Pull API"
---

## Pull API

The `wmill gitsync-settings pull` command is used to pull remote git-sync settings and apply them to your local `wmill.yaml` file. It synchronizes your local configuration with the workspace git-sync settings.

```bash
wmill gitsync-settings pull [options]
```

### Options

| Option                        | Parameter             | Description                                                                                                                                                                                                          |
| ----------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-h, --help`                  | None                  | Show help options.                                                                                                                                                                                                   |
| `--repository`                | `<repository>`        | Specify repository path (e.g., u/user/repo). If not specified, will auto-select if only one repository exists or prompt for selection.                                                                              |
| `--default`                   | None                  | Write settings to top-level defaults instead of branch-specific overrides.                                                                                                                                          |
| `--replace`                   | None                  | Replace existing settings (non-interactive mode). Overwrites top-level wmill.yaml settings.                                                                                                                         |
| `--override`                  | None                  | Add branch-specific override (non-interactive mode). Creates branch-specific configuration in git_branches section.                                                                                                 |
| `--diff`                      | None                  | Show differences without applying changes. Preview what would be modified in your local configuration.                                                                                                              |
| `--json-output`               | None                  | Output in JSON format. Useful for scripting and automation.                                                                                                                                                         |
| `--with-backend-settings`     | `<json>`              | Use provided JSON settings instead of querying backend (primarily for testing purposes).                                                                                                                            |
| `--yes`                       | None                  | Skip interactive prompts and use default behavior. The command proceeds automatically without user intervention.                                                                                                     |
| `--promotion`                 | `<branch>`            | Use promotionOverrides from the specified branch instead of regular overrides.                                                                                                                                      |
| `--workspace`                 | `<workspace>`         | Specify the target workspace. This overrides the default workspace.                                                                                                                                                  |
| `--debug`, `--verbose`        | None                  | Show debug/verbose logs.                                                                                                                                                                                             |
| `--token`                     | `<token>`             | Specify an API token. This will override any stored token.                                                                                                                                                           |
| `--base-url`                  | `<baseUrl>`           | Specify the base URL of the API. If used, `--token` and `--workspace` are required and no local remote/workspace will be used.                                                                                       |
