---
doc_id: meta/core_concepts/index
chunk_id: meta/core_concepts/index#chunk-3
heading_path: ["Core concepts", "Windmill features"]
chunk_type: prose
tokens: 847
summary: "Windmill features"
---

## Windmill features

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Architecture"
		description="Schema of Windmill architecture"
		href="/docs/misc/architecture"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
	<DocCard
		title="Instant preview & testing"
		description="Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
	<DocCard
		title="Rich display rendering"
		description="The result renderer in Windmill supports rich display rendering, allowing you to customize the display format of your results."
		href="/docs/core_concepts/rich_display_rendering"
	/>
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a package.json directly."
		href="/docs/advanced/imports"
	/>
	<DocCard
		title="Workspace dependencies"
		description="Centralized dependency management at the workspace level for shared dependency files across scripts."
		href="/docs/core_concepts/workspace_dependencies"
	/>
	<DocCard
		title="Workflows as code"
		description="Automate tasks and their flow with only code."
		href="/docs/core_concepts/workflows_as_code"
	/>
	<DocCard
		title="Draft and deploy"
		description="Develop and cooperate in a structured way."
		href="/docs/core_concepts/draft_and_deploy"
	/>
	<DocCard
		title="Persistent storage & databases"
		description="Ensure that your data is safely stored and easily accessible whenever required."
		href="/docs/core_concepts/persistent_storage"
	/>
	<DocCard
		title="Object storage in Windmill"
		description="Windmill comes with native integrations with S3, Azure Blob, AWS OIDC and Google Cloud Storage, making it the recommended storage for large objects like files and binary data."
		href="/docs/core_concepts/object_storage_in_windmill"
	/>
	<DocCard
		title="Data pipelines"
		description="Windmill enables building fast, powerful, reliable, and easy-to-build data pipelines."
		href="/docs/core_concepts/data_pipelines"
	/>
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
	/>
	<DocCard
		title="Authentification"
		description="Windmill provides flexible authentication options to ensure secure access to the platform."
		href="/docs/core_concepts/authentification"
	/>
	<DocCard
		title="Error handling"
		description="There are 5 ways to do error handling in Windmill."
		href="/docs/core_concepts/error_handling"
	/>
	<DocCard
		title="Jobs"
		description="A job represents a past, present or future `task` or `work` to be executed by a worker."
		href="/docs/core_concepts/jobs"
	/>
	<DocCard
		title="Jobs runs"
		description="Get an aggregated view of past and future runs on your workspace."
		href="/docs/core_concepts/monitor_past_and_future_runs"
	/>
	<DocCard
		title="Resources and resource types"
		description="Resources are structured configurations and connections to third-party systems, with Resource types defining the schema for each Resource."
		href="/docs/core_concepts/resources_and_types"
	/>
	<DocCard
		title="Variables and secrets"
		description="Variables and secrets are encrypted, dynamic values used for reusing information and securely passing sensitive data within scripts."
		href="/docs/core_concepts/variables_and_secrets"
	/>
	<DocCard
		title="Assets"
		description="Visualize your data flow and automatically track where your assets are used"
		href="/docs/core_concepts/assets"
	/>
	<DocCard
		title="Environment variables"
		description="Environment variables are used to configure the behavior of scripts and services, allowing for dynamic and flexible execution across different environments."
		href="/docs/core_concepts/environment_variables"
	/>
	<DocCard
		title="Groups and folders"
		description="Groups and folders enable efficient permission management by grouping users with similar access levels."
		href="/docs/core_concepts/groups_and_folders"
	/>
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="Workspace secret encryption"
		description="When updating the encryption key of a workspace, all secrets will be re-encrypted with the new key and the previous key will be replaced by the new one."
		href="/docs/core_concepts/workspace_secret_encryption"
	/>
	<DocCard
		title="Caching"
		description="Caching is used to cache the results of a script, flow, flow step or app inline scripts for a specified number of seconds."
		href="/docs/core_concepts/caching"
	/>
	<DocCard
		title="Handling files and binary data"
		description="In Windmill, JSON is the primary data format used for representing information. When working with binary data, such as files, they are represented as Base64 encoded strings."
		href="/docs/core_concepts/files_binary_data"
	/>
	<DocCard
		title="Service logs"
		description="View logs from any worker or servers directly within the service logs section of the search modal."
		href="/docs/core_concepts/service_logs"
	/>
	<DocCard
		title="Preprocessors"
		description="Preprocessors are used to transform incoming requests before they are passed to the runnable."
		href="/docs/core_concepts/preprocessors"
	/>
	<DocCard
		title="Search bar"
		description="Navigate through workspace pages & content."
		href="/docs/core_concepts/search_bar/"
	/>
	<DocCard
		title="Collaboration in Windmill"
		description="Collaboration in Windmill is simplified through various features and workflows."
		href="/docs/core_concepts/collaboration"
	/>
	<DocCard
		title="Windmill AI"
		description="Have AI complete code on Windmill."
		href="/docs/core_concepts/ai_generation"
	/>
	<DocCard
		title="AI Agents"
		description="Integrate AI agent steps directly into your Windmill flows."
		href="/docs/core_concepts/ai_agents"
	/>
</div>
