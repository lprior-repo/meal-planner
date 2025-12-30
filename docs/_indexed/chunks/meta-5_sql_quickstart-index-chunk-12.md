---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-12
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Streaming large query results to S3 (Enterprise feature)"]
chunk_type: prose
tokens: 84
summary: "Streaming large query results to S3 (Enterprise feature)"
---

## Streaming large query results to S3 (Enterprise feature)

Sometimes, your SQL script will return too much data which exceeds the 10 000 rows query limit within Windmill. In this case, you will want to use the s3 flag to stream your query result to a file.

<DocCard
	title="SQL to S3 streaming"
	description="Stream an SQL query large result to a workspace storage file"
	href="/docs/core_concepts/sql_to_s3_streaming"
/>
