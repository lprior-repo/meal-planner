---
doc_id: tutorial/windmill/structured-databases
chunk_id: tutorial/windmill/structured-databases#chunk-3
heading_path: ["Big structured SQL data: Postgres (Supabase, Neon.tech)", "Database studio"]
chunk_type: prose
tokens: 170
summary: "Database studio"
---

## Database studio

From Windmill [App editor](../../apps/0_app_editor/index.mdx), you can use the [Database studio](../../apps/4_app_configuration_settings/database_studio.mdx) component to visualize and manage your databases ([PostgreSQL](./meta-windmill-index-91.md#postgresql) / [MySQL](./meta-windmill-index-91.md#mysql) / [MS SQL](./meta-windmill-index-91.md#ms-sql) / [Snowflake](./meta-windmill-index-91.md#snowflake) / [BigQuery](./meta-windmill-index-91.md#bigquery)).

![Database studio](../../assets/apps/4_app_component_library/db_studio.png "Database studio")

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/Fd_0EffVDtw"
	title="Database studio"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

The Database studio component allows you to:
- Display the content of a table.
- Edit the content of a table by directly editing the cells (only when the cell is editable).
- Add a new row.
- Delete a row.

All details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Database studio"
		description="The Database studio is a web-based database management tool that leverages Ag Grid for table display and interaction"
		href="/docs/apps/app_configuration_settings/database_studio"
	/>
</div>
