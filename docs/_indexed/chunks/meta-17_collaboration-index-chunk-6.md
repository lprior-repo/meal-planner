---
doc_id: meta/17_collaboration/index
chunk_id: meta/17_collaboration/index#chunk-6
heading_path: ["Collaboration in Windmill", "Git integration"]
chunk_type: prose
tokens: 321
summary: "Git integration"
---

## Git integration

Windmill supports 2-way sync from any source control (hence github and gitlab, but also any other source control) leveraging our [CLI](./meta-3_cli-index.md) and CI actions. The CLI can pull a workspace locally (of all the items one has permission on, if admin, it will be the entire workspace) and push local changes to the remote. The CLI has an internal state stored in .wmill which can detect conflicts when changes have been made both locally and on the remote.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/TXtmLrToxoI"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

You can use this to:

1. Backup regularly your workspaces to git.

2. Develop locally using your favorite [code editor](./meta-1_vscode-extension-index.md) and push changes to the remote.

3. Implement a dev/staging/prod workflow where changes are automatically pulled from one workspace and transformed into a pull request. And only once the pull request is approved are the changes deployed to the target workspace. This enable full GitOps style of deployments while still allowing users to use the web UI to edit scripts/flows/apps/.

![VS Code Extention](../../../blog/2023-11-20-vscode/vscode_extension.png.webp 'VS Code extension')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Command-line interface (CLI)"
		description="The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
	<DocCard
		title="VS Code extension"
		description="Build scripts and flows in the comfort of your VS Code editor, while leveraging Windmill UIs for test & flows edition."
		href="/docs/cli_local_dev/vscode-extension"
	/>
</div>
