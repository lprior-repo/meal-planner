---
doc_id: meta/52_assets/index
chunk_id: meta/52_assets/index#chunk-1
heading_path: ["Assets"]
chunk_type: prose
tokens: 262
summary: "Assets"
---

# Assets

> **Context**: Assets are designed to track data flows and visualize data sets, automatically detecting when you reference them directly in your code. Assets are ref

Assets are designed to track data flows and visualize data sets, automatically detecting when you reference them directly in your code. Assets are referenced with URIs and include:

- [S3 objects](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage) : s3://storage/path/to/file.csv
- [Resources](./meta-3_resources_and_types-index.md) : res://path/to/resource

![Assets in script editor](./assets_in_script_editor.png 'Assets in script editor')

As of writing this, assets are supported for the following languages:

- [Python](./meta-2_python_quickstart-index.md)
- [JavaScript / TypeScript](./meta-1_typescript_quickstart-index.md)
- [DuckDB](./meta-5_sql_quickstart-index.md#duckdb)

When the asset is a database resource or an S3 file, an explore button will appear next to the asset with access to the [database manager](./meta-3_resources_and_types-index.md#database-manager).

Read / Write mode is infered from code context.
For example, a `COPY (...) TO file` statement is always `Write`.
Sometimes the Read / Write mode cannot be inferred, in which case you are able to manually select it.

You can use the Add Resource / S3 Object buttons in the editor bar for convenience :

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="main-video"
	src="/videos/assets_demo.mp4"
/>
<br />

The python and Typescript/Javascript clients now support the new URI syntax :

```python
wmill.get_resource('res://path/to/resource')
wmill.load_s3_file('s3://storage/path/to/file.csv')
