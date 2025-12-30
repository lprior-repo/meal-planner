---
doc_id: meta/14_dependencies_in_typescript/index
chunk_id: meta/14_dependencies_in_typescript/index#chunk-4
heading_path: ["Dependencies in TypeScript", "Bundle per script built by CLI"]
chunk_type: prose
tokens: 195
summary: "Bundle per script built by CLI"
---

## Bundle per script built by CLI

This method can only be deployed from the [CLI](./meta-3_cli-index.md), on [local development](./meta-4_local_development-index.md).

To work with large custom codebases, there is another mode of deployment that relies on the same mechanism as similar services like Lambda or cloud functions: a bundle is built locally by the CLI using [esbuild](https://esbuild.github.io/) and deployed to Windmill.

This bundle contains all the code and dependencies needed to run the script.

Windmill CLI, it is done automatically on `wmill sync push` for any script that falls in the patterns of includes and excludes as defined by the [wmill.yaml](./meta-33_codebases_and_bundles-index.md#wmillyaml) (in the codebase field).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/RYljT-l-cIE"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Codebases & bundles"
		description="Deploy scripts with any local relative imports as bundles."
		href="/docs/core_concepts/codebases_and_bundles"
	/>
</div>
