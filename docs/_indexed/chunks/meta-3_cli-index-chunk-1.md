---
doc_id: meta/3_cli/index
chunk_id: meta/3_cli/index#chunk-1
heading_path: ["Command-line interface (CLI)"]
chunk_type: prose
tokens: 150
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Command-line interface (CLI)

> **Context**: import DocCard from '@site/src/components/DocCard';

The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your
terminal.

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

You can also use it for various automation tasks, including
[syncing](./ops-3_cli-sync.md) folders &
[GitHub repositories](./ops-3_cli-sync.md), or just running all you scripts and flows.

See [Installation](./ops-3_cli-installation.md) for getting started.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Installation"
		description="How to install the CLI"
		href="/docs/advanced/cli/installation"
	/>
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
</div>
