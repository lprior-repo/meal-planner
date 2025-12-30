---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-1
heading_path: ["Git sync"]
chunk_type: prose
tokens: 171
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Git sync

> **Context**: import DocCard from '@site/src/components/DocCard';

From the workspace settings, you can set a [git_repository](../../integrations/git_repository.mdx) resource on which the workspace will automatically commit and push scripts, flows and apps to the repository on each [deploy](./meta-0_draft_and_deploy-index.md).

You can use this feature to [Deploy to prod using a git workflow](#git-sync---promotion-mode-deploy-to-prod-using-a-git-workflow).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Deploy to prod"
		description="Deploy to prod using a staging workspace"
		href="/docs/advanced/deploy_to_prod"
	/>
</div>

:::tip Version control

For all details on Version control in Windmill, see [Version control](./meta-13_version_control-index.md).

:::

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
