---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-8
heading_path: ["Git sync", "Git sync - Promotion mode: Deploy to prod using a git workflow"]
chunk_type: prose
tokens: 211
summary: "Git sync - Promotion mode: Deploy to prod using a git workflow"
---

## Git sync - Promotion mode: Deploy to prod using a git workflow

This feature can be used alongside GiHub Actions to adopt a robust development process for your Windmill scripts, flows and apps,
with for example a Staging Workspace making automatically PRs on a repo that pushes to a Prod workspace upon merge.

![Local development Setup](../4_local_development/local_development.png 'Local development Setup')

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/es8FUC2M73o"
	title="Deploy to a Prod Workspace using a Git Workflow"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

More details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Deploy to prod using a git workflow"
		description="Windmill integration with Git repositories makes it possible to adopt a robust development process for your Windmill scripts, flows and apps."
		href="/docs/advanced/deploy_gh_gl"
	/>
	<DocCard
		title="Local development"
		description="Develop locally, push to git and deploy automatically to Windmill."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="GitHub App"
		description="Install the Windmill GitHub app to simplify setting up Git sync"
		href="/docs/integrations/git_repository#github-app"
	/>
</div>
