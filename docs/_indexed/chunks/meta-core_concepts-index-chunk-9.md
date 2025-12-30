---
doc_id: meta/core_concepts/index
chunk_id: meta/core_concepts/index#chunk-9
heading_path: ["Core concepts", "Enterprise & cloud features"]
chunk_type: prose
tokens: 768
summary: "Enterprise & cloud features"
---

## Enterprise & cloud features

All details & features on [Pricing page](/pricing).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Enterprise onboarding"
		description="Essential setup information and best practices for new enterprise self-hosted customers."
		href="/docs/misc/enterprise_onboarding"
	/>
	<DocCard
		title="Support & SLA"
		description="Our SLAs are designed to provide timely assistance and address any issues."
		href="/docs/misc/support_and_sla"
	/>
	<DocCard
		title="Audit logs"
		description="Windmill provides audit logs for every operation and action that has side-effects."
		href="/docs/core_concepts/audit_logs"
	/>
	<DocCard
		title="Worker groups management UI"
		description="Manage Worker Groups through Windmill UI."
		href="/docs/misc/worker_group_management_ui"
	/>
	<DocCard
		title="Autoscaling"
		description="Autoscaling automatically adjusts the number of workers based on your workload demands."
		href="/docs/core_concepts/autoscaling"
	/>
	<DocCard
		title="Deploy to prod using the UI"
		description="Deploy items to another staging/prod workspace."
		href="/docs/core_concepts/staging_prod"
	/>
	<DocCard
		title="Git sync"
		description="Connect a Windmill workspace to a Git repository to automatically commit and push scripts, flows and apps to the repository on each deploy."
		href="/docs/advanced/git_sync"
	/>
	<DocCard
		title="Concurrency limits"
		description="The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows."
		href="/docs/core_concepts/concurrency_limits"
	/>
	<DocCard
		title="Job debouncing"
		description="Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics."
		href="/docs/core_concepts/job_debouncing"
	/>
	<DocCard
		title="Instance object storage distributed cache for Python, Rust, Go"
		description="Leverage a global S3 cache to speed up Python dependency handling by storing and reusing pre-installed package."
		href="/docs/misc/s3_cache"
	/>
	<DocCard
		title="OpenID Connect (OIDC)"
		description="Use Windmill's OIDC provider to authenticate from scripts to cloud providers and other APIs."
		href="/docs/core_concepts/oidc"
	/>
	<DocCard
		title="SAML & SCIM"
		description="Configure Okta or Microsoft for both SAML and SCIM."
		href="/docs/misc/saml_and_scim"
	/>
	<DocCard
		title="External auth with JWT"
		description="Generate your own JWT tokens with the desired permissions for your already authenticated users and pass them to Windmill."
		href="/docs/advanced/external_auth_with_jwt"
	/>
	<DocCard
		title="Dedicated workers / High throughput"
		description="Dedicated Workers are workers that are dedicated to a particular script."
		href="/docs/core_concepts/dedicated_workers"
	/>
	<DocCard
		title="Agent workers"
		description="Agent workers are a 4th mode of execution of the Windmill binary, but instead of using MODE=worker, we use here MODE=agent."
		href="/docs/core_concepts/agent_workers"
	/>
	<DocCard
		title="Critical alerts"
		description="Get a notification everytime a job is re-run after a crash."
		href="/docs/core_concepts/critical_alerts"
	/>
	<DocCard
		title="Content search"
		description="Search any scripts, flows, resources, apps for a specific string similar to GitHub search."
		href="/docs/core_concepts/content_search"
	/>
	<DocCard
		title="Codebases & bundles"
		description="Deploy scripts with any local relative imports as bundles."
		href="/docs/core_concepts/codebases_and_bundles"
	/>
	<DocCard
		title="CSS editor"
		description="The Global CSS editor is designed to give styling and theming across your entire app."
		href="/docs/apps/css_editor"
	/>
	<DocCard
		title="Multiplayer"
		description="Collaborate on scripts simultaneously."
		href="/docs/core_concepts/multiplayer"
	/>
	<DocCard
		title="Private Hub"
		description="Host your own Hub of scripts, flows, apps and resource types for your team."
		href="/docs/core_concepts/private_hub"
	/>
	<DocCard
		title="White labeling Windmill"
		description="Windmill offers white labeling capabilities, allowing you to embed and customize the Windmill platform to align with your brand."
		href="/docs/misc/white_labelling"
	/>
	<DocCard
		title="Windmill React SDK"
		description="The Windmill React SDK provides a suite of tools and components to integrate Windmill applications into React-based projects."
		href="/docs/misc/react_sdk"
	/>
	<DocCard
		title="Windows workers"
		description="Windows workers enable you to run Windmill scripts and flows directly on Windows machines without requiring Docker or WSL, supporting Python, Bun, PowerShell, C#, and Nu executors for native Windows execution."
		href="/docs/misc/windows_workers"
	/>
	<DocCard
		title="Private Hub"
		description="Host your own Hub of scripts, flows, apps and resource types for your team."
		href="/docs/core_concepts/private_hub"
	/>
	<DocCard
		title="White labeling Windmill"
		description="Windmill offers white labeling capabilities, allowing you to embed and customize the Windmill platform to align with your brand."
		href="/docs/misc/white_labelling"
	/>
	<DocCard
		title="Full text search"
		description="Full text search on jobs and service logs, allowing quick access and good observability out of the box. Learn how to set it up."
		href="/docs/misc/full_text_search"
	/>
	<DocCard
		title="SQL to S3 streaming"
		description="Stream an SQL query large result to a workspace storage file"
		href="/docs/core_concepts/sql_to_s3_streaming"
	/>
</div>
