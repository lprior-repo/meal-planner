---
doc_id: meta/5_sharing_common_logic/index
chunk_id: meta/5_sharing_common_logic/index#chunk-1
heading_path: ["Sharing common logic"]
chunk_type: prose
tokens: 193
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Sharing common logic

> **Context**: import DocCard from '@site/src/components/DocCard';

It is common to want to share common logic between your scripts. This can be done easily using relative imports in both [Python](./meta-2_python_quickstart-index.md) and [TypeScript](./meta-1_typescript_quickstart-index.md).

Note that in both the webeditor and with the [CLI](./meta-3_cli-index.md), your scripts do not necessarily need to have a main function. If they don't, they are assumed to be shared logic and not runnable scripts.

It works extremely well in combination with [Developing scripts locally](./meta-4_local_development-index.md) and you can easily sync your scripts with the CLI.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
	/>
	<DocCard
		title="Dependencies in Python"
		description="How to manage dependencies in Python scripts."
		href="/docs/advanced/dependencies_in_python"
	/>
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a package.json directly."
		href="/docs/advanced/imports"
	/>
</div>
