---
doc_id: tutorial/flows/3-editor-components
chunk_id: tutorial/flows/3-editor-components#chunk-9
heading_path: ["Flow editor components", "Inline action script"]
chunk_type: prose
tokens: 214
summary: "Inline action script"
---

## Inline action script

You can either create a new action script in:

- [Python](./meta-2_python_quickstart-index.md): Windmill provides a Python 3.11 environment.
- [TypeScript](./meta-1_typescript_quickstart-index.md): Windmill uses Deno as the TypeScript runtime.
- [Go](./meta-3_go_quickstart-index.md).
- [Bash](./meta-4_bash_quickstart-index.md).
- [Nu](./meta-4_bash_quickstart-index.md).
- Any language [running any docker container](./meta-7_docker-index.md) through Windmill's bash support.

There are special kinds of scripts, [SQL and query languages](./meta-5_sql_quickstart-index.md):

- Postgres
- MySQL
- MS SQL
- BigQuery
- Snowflake

- [Rest](./meta-6_rest_grapqhql_quickstart-index.md)
- [GrapQL](./meta-6_rest_grapqhql_quickstart-index.md)
- [Powershell](./meta-4_bash_quickstart-index.md)

These are essentially TypeScript template to easily write queries to a database.

### Triggering an action script from the Hub

You can refer to and trigger an action script from the [Hub](https://hub.windmill.dev/). You also have the possibility to fork it (copy it as an inline script) directly to modify its behavior.

### Triggering an action script from the workspace

You can refer to and trigger an action script from the workspace. Similar to the previous section, you can copy the script to an inline flow script and modify it.

![Flow action](../assets/flows/flow_new_action.png.webp)
