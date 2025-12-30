---
doc_id: meta/33_codebases_and_bundles/index
chunk_id: meta/33_codebases_and_bundles/index#chunk-1
heading_path: ["Codebases & bundles"]
chunk_type: prose
tokens: 159
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Codebases & bundles

> **Context**: import DocCard from '@site/src/components/DocCard';

:::note

Codebases & bundles is Beta, only works with TypeScript and is an [Enterprise](/pricing) feature for the time being.

:::

The traditional way to handle codebases on Windmill is two-fold:

- Using [relative imports](./meta-14_dependencies_in_typescript-index.md#sharing-common-logic-with-relative-imports-when-not-using-bundles) to import scripts from the same workspace.
- Deploy a private/public packages and import them in your scripts [using the package manager](./meta-14_dependencies_in_typescript-index.md#private-npm-registry--private-npm-packages).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
	/>
</div>

However, that can be inconvenient when working with large codebases.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/RYljT-l-cIE"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>
