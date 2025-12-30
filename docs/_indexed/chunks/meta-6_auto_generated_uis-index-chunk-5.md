---
doc_id: meta/6_auto_generated_uis/index
chunk_id: meta/6_auto_generated_uis/index#chunk-5
heading_path: ["Auto-generated UIs", "Build App"]
chunk_type: prose
tokens: 224
summary: "Build App"
---

## Build App

You can generate a dedicated [app](../../apps/0_app_editor/index.mdx) to execute your script or flow.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/cowsay_app.mp4"
/>

<br />

This is the recommended way to share scripts and flows with [operators](./meta-16_roles_and_permissions-index.md), with the second option being of sharing the script and [variables](./meta-2_variables_and_secrets-index.md) it depends on (but operators won't be able to load variable directly from the UI/API, only use them within the scripts they have access to).

The apps will be permissioned on behalf of the [admin/author](./meta-16_roles_and_permissions-index.md), the user is still identified at the time of execution from the [Runs](./meta-5_monitor_past_and_future_runs-index.md) and [Audit logs](./meta-14_audit_logs-index.md) menus.

![Script execution Runs menu](./script_exec_runs.png.webp 'View from the run menu')

> View from the [Runs](./meta-5_monitor_past_and_future_runs-index.md) menu.

<br />

At last, this is an easy way to get an app for your scripts and flows to be customized with [Styling](../../apps/4_app_configuration_settings/4_app_styling.mdx) and [Components](../../apps/4_app_configuration_settings/1_app_component_library.mdx).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>
