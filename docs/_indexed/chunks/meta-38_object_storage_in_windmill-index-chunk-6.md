---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-6
heading_path: ["Object storage in Windmill (S3)", "Streaming large SQL query results to S3 (Enterprise feature)"]
chunk_type: prose
tokens: 85
summary: "Streaming large SQL query results to S3 (Enterprise feature)"
---

## Streaming large SQL query results to S3 (Enterprise feature)

Sometimes, your SQL script will return too much data which exceeds the 10 000 rows query limit within Windmill. In this case, you will want to use the s3 flag to stream your query result to a file.

<DocCard
	title="SQL to S3 streaming"
	description="Stream an SQL query large result to a workspace storage file"
	href="/docs/core_concepts/sql_to_s3_streaming"
/>
