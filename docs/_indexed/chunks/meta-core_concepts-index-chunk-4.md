---
doc_id: meta/core_concepts/index
chunk_id: meta/core_concepts/index#chunk-4
heading_path: ["Core concepts", "Hosting & advanced"]
chunk_type: prose
tokens: 418
summary: "Hosting & advanced"
---

## Hosting & advanced

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Self-host"
		description="Run Windmill on your own infrastructure."
		href="/docs/advanced/self_host"
	/>
	<DocCard
		title="Windmill on AWS ECS or EKS"
		description="Windmill can be deployed on an ECS or EKS cluster."
		href="/docs/advanced/self_host/aws_eks_ecs"
	/>
	<DocCard
		title="Command-line interface"
		description="Interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Version control in Windmill"
		description="Sync your workspace to a git repository."
		href="/docs/advanced/version_control"
	/>
	<DocCard
		title="Workspace forks"
		description="Create independent copies of workspaces for parallel development workflows, similar to git branches and GitHub forks."
		href="/docs/advanced/workspace_forks"
	/>
	<DocCard
		title="Deploy to prod"
		description="Deploy to prod using a staging workspace"
		href="/docs/advanced/deploy_to_prod"
	/>
	<DocCard
		title="Preinstall binaries"
		description="Workers in Windmill can preinstall binaries. This allows them to execute these binaries in subprocesses or directly within bash."
		href="/docs/advanced/preinstall_binaries"
	/>
	<DocCard
		title="React app import"
		description="Import your own Apps in React."
		href="/docs/react_vue_svelte_apps/react"
	/>
	<DocCard
		title="Browser automation"
		description="Run browser automation scripts."
		href="/docs/advanced/browser_automation"
	/>
	<DocCard
		title="Run Docker containers"
		description="Windmill supports running any docker container through its bash integration."
		href="/docs/advanced/docker"
	/>
	<DocCard
		title="Setup OAuth and SSO"
		description="Windmill supports Single Sign-On for Microsoft, Google, GitHub, GitLab, Okta, and domain restriction."
		href="/docs/misc/setup_oauth"
	/>
	<DocCard
		title="Sharing common logic"
		description="It is common to want to share common logic between your scripts. This can be done easily using relative imports in both Python and TypeScript."
		href="/docs/advanced/sharing_common_logic"
	/>
	<DocCard
		title="TypeScript client"
		description="The TypeScript client for Windmill allows you to interact with the Windmill platform using TypeScript in Bun / Deno runtime."
		href="/docs/advanced/clients/ts_client"
	/>
	<DocCard
		title="Python client"
		description="The Python client library for Windmill provides a convenient way to interact with the Windmill platform's API from within your script jobs."
		href="/docs/advanced/clients/python_client"
	/>
	<DocCard
		title="Set/Get progress from code"
		description="You can now set progress of script execution from within the script (Python and TypeScript)"
		href="/docs/advanced/explicit_progress"
	/>
	<DocCard
		title="Share on Windmill Hub"
		description="Share your scripts, flows, apps and resource types on Windmill Hub."
		href="/docs/misc/share_on_hub"
	/>
</div>
