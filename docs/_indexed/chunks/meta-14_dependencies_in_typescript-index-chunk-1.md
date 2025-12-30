---
doc_id: meta/14_dependencies_in_typescript/index
chunk_id: meta/14_dependencies_in_typescript/index#chunk-1
heading_path: ["Dependencies in TypeScript"]
chunk_type: prose
tokens: 276
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Dependencies in TypeScript

> **Context**: import DocCard from '@site/src/components/DocCard';

In Windmill [standard mode](#lockfile-per-script-inferred-from-imports-standard), dependencies in [TypeScript](./meta-1_typescript_quickstart-index.md) are handled directly within their scripts without the need to manage separate dependency files.
For TypeScript, there are two runtime options available: [Bun](https://bun.sh/) and [Deno](https://deno.land/).
Both of these runtimes allow you to include dependencies directly in the script, and Windmill automatically handles the resolution and caching of these dependencies to ensure fast and consistent execution (this is standard mode).

There are however methods to have more control on your dependencies:

- Leveraging [standard mode](#lockfile-per-script-inferred-from-imports-standard) on [web IDE](#web-ide) or [locally](#cli).
- Overriding dependencies [providing a package.json](#lockfile-per-script-inferred-from-a-packagejson).
- [Bundling](#bundle-per-script-built-by-cli) per script with CLI, more powerful and local only.

Moreover, there are other tricks, compatible with the methodologies mentioned above:

- [Sharing common logic with Relative Imports](#sharing-common-logic-with-relative-imports-when-not-using-bundles) when not using Bundles.
- [Private npm registry & private npm packages](#private-npm-registry--private-npm-packages).

To learn more about how dependencies from other languages are handled, see [Dependency management & imports](./meta-6_imports-index.md).

![Dependency management & imports](../6_imports/dependency_management.png 'Dependency management & imports')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a package.json directly."
		href="/docs/advanced/imports"
	/>
	<DocCard
		title="Dependencies in Python"
		description="How to manage dependencies in Python scripts."
		href="/docs/advanced/dependencies_in_python"
	/>
</div>
