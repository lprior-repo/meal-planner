---
doc_id: meta/23_instant_preview/index
chunk_id: meta/23_instant_preview/index#chunk-2
heading_path: ["Instant preview & testing", "Instant preview in Script editor"]
chunk_type: prose
tokens: 256
summary: "Instant preview in Script editor"
---

## Instant preview in Script editor

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/auto_g_ui_landing.mp4"
/>

<br />

The right margin of the script editor displays:

1. The inputs of the main function, which are parsed to create an auto-generated UI.
2. The logs and results of the last execution.
3. The history of the latest runs via the editor.

![Auto-generated UI, logs and results](./auto_g_logs.png 'Auto-generated UI, logs and results')

![Test history](./test_history.png 'Test history')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script editor"
		description="Scripts are the basic building blocks that can be written in TypeScript, Python, Go, PHP, Bash, C#, SQL and Rust or launch docker containers."
		href="/docs/script_editor"
	/>
</div>

### VS Code extension

For users on [VS Code extension](./meta-1_vscode-extension-index.md), you can also preview instantly and test with the `Windmill: Run preview` command.

![VS Code Extention](../../../blog/2023-11-20-vscode/vscode_extension.png 'VS Code extension')

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/aSOF6AzyDr8"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="VS Code extension"
		description="Build scripts and flows in the comfort of your VS Code editor, while leveraging Windmill UIs for test & flows edition."
		href="/docs/cli_local_dev/vscode-extension"
	/>
</div>
