---
doc_id: meta/5_sharing_common_logic/index
chunk_id: meta/5_sharing_common_logic/index#chunk-9
heading_path: ["Sharing common logic", "Tracking relative imports on local development"]
chunk_type: prose
tokens: 197
summary: "Tracking relative imports on local development"
---

## Tracking relative imports on local development

On [local development](./meta-4_local_development-index.md), Windmill automatically tracks relative imports in Bun and Python such that if you update a common dependency and update its imports, it will now re-trigger deployment and [lockfile](./meta-6_imports-index.md) computation of all the scripts that depend on it (it was working for Python but not Bun before).

When doing `wmill sync pull`, the wmill-lock.yaml will now automatically be updated, avoiding re-triggering lockfile computation for all files, only the ones that have changed from last sync.

Windmill can also track such imports in inline scripts of flows and will surgically update the inline lockfiles of those flows if the relative imports change.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop locally, push to git and deploy automatically to Windmill."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Command-line interface (CLI)"
		description="The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
</div>
