---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-5
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Contextual variables"]
chunk_type: prose
tokens: 31
summary: "Contextual variables"
---

## Contextual variables

You can use [contextual variables](./meta-47_environment_variables-index.md#contextual-variables) in your queries. They need to be wrapped in `%%` like this:

```sql
SELECT '%%WM_WORKSPACE%%'
```
