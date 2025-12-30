---
doc_id: meta/1_vscode-extension/index
chunk_id: meta/1_vscode-extension/index#chunk-5
heading_path: ["VS Code extension", "Settings"]
chunk_type: prose
tokens: 257
summary: "Settings"
---

## Settings

The extension automatically uses workspace settings from your Windmill CLI configuration if available. This provides seamless integration between the CLI and VS Code extension without needing to configure settings separately.

The extension provides the following settings:

| Setting                         | Description                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `windmill.remote`               | The full remote URL including http and trailing slash. By default, it's "https://app.windmill.dev/".         |
| `windmill.workspaceId`          | The workspace id to use.                                                                                     |
| `windmill.token`                | The [token](./meta-4_webhooks-index.md#user-token) to use to authenticate with the remote and workspace.                                              |
| `windmill.additionalWorkspaces` | The list of additional remotes to use. This allows you to set up multiple workspaces for different projects. |
| `windmill.currentWorkspace`     | The workspace name currently used (if multiple). main or empty is the default one.                           |
| `windmill.configFolder`         | Override the CLI config folder path to fetch the workspace settings from.                                    |

![demo](./wm-settings.png.webp)

You can create a user token in the Windmill app. Follow the instructions on the [Webhooks docs](./meta-4_webhooks-index.md#user-token).

For TypeScript scripts, the Windmill extension will use by default [Bun](./meta-1_typescript_quickstart-index.md) as the runtime. You can change it either per script by using file extension `.deno.ts` or globally in your [wmill.yaml](./ops-3_cli-sync.md#wmillyaml) in the field `defaultTs`.
