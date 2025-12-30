---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-9
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Customize your script"]
chunk_type: prose
tokens: 137
summary: "Customize your script"
---

## Customize your script

After you're done, click on "[Deploy](./meta-0_draft_and_deploy-index.md)", which will save it to your workspace. You can now use this Script in your [Flows](./tutorial-flows-1-flow-editor.md), [app](../../../apps/0_app_editor/index.mdx) or as standalone.

Feel free to customize your script's metadata ([path](./meta-16_roles_and_permissions-index.md#path), name, description),
runtime ([concurrency limits](./ref-script_editor-concurrency-limit.md), [worker group](./tutorial-script_editor-settings.md#worker-group-tag),
[cache](./meta-24_caching-index.md), [dedicated workers](./meta-25_dedicated_workers-index.md)) and [generated UI](./tutorial-script_editor-customize-ui.md).

![Customize SQL](./customize_sql.png 'Customize SQL')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>
