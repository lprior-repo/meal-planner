---
doc_id: meta/1_vscode-extension/index
chunk_id: meta/1_vscode-extension/index#chunk-1
heading_path: ["VS Code extension"]
chunk_type: prose
tokens: 327
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# VS Code extension

> **Context**: import DocCard from '@site/src/components/DocCard';

The Windmill VS Code extension allows you to build scripts and flows in the comfort of your VS Code editor, while leveraging Windmill UIs for test & flows edition.

![VS Code extension](../../../blog/2023-11-20-vscode/vscode_extension.png 'VS Code extension')

The extension can be used in particular from a repository synchronized to a Windmill instance to [develop scripts & flows locally](./meta-4_local_development-index.md) while keeping them synced to your workspace.

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

Windmill has its own IDE for creating [scripts](./meta-script_editor-index.md) and [flows](./tutorial-flows-1-flow-editor.md) from the Windmill application (cloud or [self-hosted](./meta-1_self_host-index.md)).

The Windmill UI allows you to edit directly the deployed scripts & flows, which is great for maintenance and quick prototyping.

However in many production settings it is more common to version everything from Git and to that end we have a CLI to sync a workspace to a local directory and the inverse operation (deploy local directory to a workspace). With this extension, you can efficiently edit scripts & flows directly from there.

To run scripts locally, see [Run locally](./ops-4_local_development-run-locally.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Run locally"
		description="Run scripts locally that interact with a Windmill instance."
		href="/docs/advanced/local_development/run_locally"
	/>
	<DocCard
		title="Command-line interface"
		description="Interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
</div>
