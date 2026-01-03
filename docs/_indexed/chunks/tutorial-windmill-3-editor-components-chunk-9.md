---
doc_id: tutorial/windmill/3-editor-components
chunk_id: tutorial/windmill/3-editor-components#chunk-9
heading_path: ["Flow editor components", "Inline action script"]
chunk_type: prose
tokens: 214
summary: "Inline action script"
---

## Inline action script

You can either create a new action script in:

- [Python](./meta-windmill-index-88.md): Windmill provides a Python 3.11 environment.
- [TypeScript](./meta-windmill-index-87.md): Windmill uses Deno as the TypeScript runtime.
- [Go](./meta-windmill-index-89.md).
- [Bash](./meta-windmill-index-90.md).
- [Nu](./meta-windmill-index-90.md).
- Any language [running any docker container](./meta-windmill-index-18.md) through Windmill's bash support.

There are special kinds of scripts, [SQL and query languages](./meta-windmill-index-91.md):

- Postgres
- MySQL
- MS SQL
- BigQuery
- Snowflake

- [Rest](./meta-windmill-index-92.md)
- [GrapQL](./meta-windmill-index-92.md)
- [Powershell](./meta-windmill-index-90.md)

These are essentially TypeScript template to easily write queries to a database.

### Triggering an action script from the Hub

You can refer to and trigger an action script from the [Hub](https://hub.windmill.dev/). You also have the possibility to fork it (copy it as an inline script) directly to modify its behavior.

### Triggering an action script from the workspace

You can refer to and trigger an action script from the workspace. Similar to the previous section, you can copy the script to an inline flow script and modify it.

![Flow action](../assets/flows/flow_new_action.png.webp)
