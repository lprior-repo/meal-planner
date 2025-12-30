---
doc_id: meta/12_deploy_to_prod/index
chunk_id: meta/12_deploy_to_prod/index#chunk-3
heading_path: ["Deploy to prod", "Option 2. Deploy to prod using a git workflow - Multi workspace (recommended)"]
chunk_type: prose
tokens: 153
summary: "Option 2. Deploy to prod using a git workflow - Multi workspace (recommended)"
---

## Option 2. Deploy to prod using a git workflow - Multi workspace (recommended)

The integration can be used to push from git, and receive changes done from the UI in a bi-directional way.
You can also use a separate dev and staging branch and repo and have Windmill create automatically branches and Pull Request upon any changes deployed to staging/dev.

This process can be used in particular for [local development](./meta-4_local_development-index.md) with a solid setup:

![Local development Setup](../4_local_development/local_development.png 'Local development Setup')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Deploy to prod using a git workflow"
		description="Windmill integration with Git repositories makes it possible to adopt a robust development process for your Windmill scripts, flows and apps."
		href="/docs/advanced/deploy_gh_gl"
	/>
</div>
