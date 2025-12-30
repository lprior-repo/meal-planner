---
doc_id: meta/13_version_control/index
chunk_id: meta/13_version_control/index#chunk-2
heading_path: ["Version control", "Git sync"]
chunk_type: prose
tokens: 158
summary: "Git sync"
---

## Git sync

From the workspace settings, you can set a [git_repository](../../integrations/git_repository.mdx) resource on which the workspace will automatically commit and push scripts, flows and apps to the repository on each [deploy](./meta-0_draft_and_deploy-index.md).

This video shows how to set up a Git repository for a workspace (Git sync - sync mode).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/cHrREDmrnUM?vq=hd1080&hd=1&quality=highres"
	title="Git sync"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Git sync is [Cloud plans and Self-Hosted Enterprise Edition](/pricing) only.

More details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Git sync"
		description="Connect a Windmill workspace to a Git repository to automatically commit and push scripts, flows and apps to the repository on each deploy."
		href="/docs/advanced/git_sync"
	/>
</div>
