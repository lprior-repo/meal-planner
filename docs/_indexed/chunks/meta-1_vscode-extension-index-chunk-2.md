---
doc_id: meta/1_vscode-extension/index
chunk_id: meta/1_vscode-extension/index#chunk-2
heading_path: ["VS Code extension", "Installation"]
chunk_type: prose
tokens: 211
summary: "Installation"
---

## Installation

First of all, have your workspace synced locally with [Windmill CLI](./meta-3_cli-index.md).

![Local workspace](../../../blog/2023-11-20-vscode/local_workspace.png.webp)

> [Example repo](https://github.com/windmill-labs/windmill-sync-example) opened in VS Code. We see 2 flows and 1 script, the flows are their own folders, each step in a flow is a seperate file in their respective language. Scripts have their metadata in a seperate file.

<br />

With [wmill sync pull](./ops-3_cli-sync.md#pulling) and [wmill sync push](./ops-3_cli-sync.md) you can synchronize your remote workspace to a local directory which you would version with GitHub / GitLab.

Then you can:

1. Install the [extension](https://marketplace.visualstudio.com/items?itemName=windmill-labs.windmill).

2. From any script file, use `> Windmill: Run preview in the current editor` or Ctrl+Enter and Shift+Enter to generate the UI preview (provided that the script meets the [few rules](./meta-13_json_schema_and_parsing-index.md#json-schema-in-windmill) required by Windmill).

All details to set up the workspace folder:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Setting up the workspace folder"
		description="Developing Windmill scripts and flows from your favorite IDE is made easy by using Windmill CLI."
		href="/docs/advanced/local_development#setting-up-the-workspace-folder"
	/>
</div>
