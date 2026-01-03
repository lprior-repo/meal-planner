---
doc_id: tutorial/windmill/settings
chunk_id: tutorial/windmill/settings#chunk-2
heading_path: ["Settings", "Metadata"]
chunk_type: prose
tokens: 365
summary: "Metadata"
---

## Metadata

Metadata is used to define the script's path, summary, description, language and kind.

### Summary

Summary (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.

It can be pre-filled automatically using [Windmill AI](./meta-windmill-index-37.md):

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/summary_compilot.mp4"
/>

### Path

Path is the Script's unique identifier that consists of the [script's owner](./meta-windmill-index-30.md#permissions-and-access-control), and the script's name.
The owner can be either a user, or a group of users ([folder](./meta-windmill-index-79.md#folders)).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
	/>
	<DocCard
		title="Groups and folders"
		description="Groups and folders enable efficient permission management by grouping users with similar access levels."
		href="/docs/core_concepts/groups_and_folders"
	/>
</div>

### Description

This is where you can give instructions to users on how to run your Script. It supports markdown.

### Language

Language of the script. Windmill supports:
- [TypeScript](./meta-windmill-index-87.md) (Bun & Deno)
- [Python](./meta-windmill-index-88.md)
- [Go](./meta-windmill-index-89.md)
- [Bash & Powershell & Nu](./meta-windmill-index-90.md)
- [SQL](./meta-windmill-index-91.md) (PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake)
- [Rest & GraphQL](./meta-windmill-index-92.md)
- [Docker](./meta-windmill-index-93.md)

You can configure the languages that are visible and their order.

The setting applies to scripts, flows and apps and is global to all users within a workspace but only configurable by [admins](./meta-windmill-index-30.md#admin).

![Configurable Default Languages](../assets/script_editor/configurable-languages.png 'Configurable Default Languages')

### Script kind

You can attach additional functionalities to Scripts by specializing them into specific Script kinds (Actions, Trigger, Approval, Error handler, Preprocessor).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script kind"
		description="You can attach additional functionalities to Scripts by specializing them into specific Script kinds."
		href="/docs/script_editor/script_kinds"
	/>
</div>
