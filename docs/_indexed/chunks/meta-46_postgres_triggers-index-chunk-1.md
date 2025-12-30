---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-1
heading_path: ["Postgres triggers"]
chunk_type: prose
tokens: 123
summary: "Postgres triggers"
---

# Postgres triggers

> **Context**: Windmill can connect to a [Postgres](https://www.postgresql.org/) database and trigger runnables (scripts, flows) in response to database transactions

Windmill can connect to a [Postgres](https://www.postgresql.org/) database and trigger runnables (scripts, flows) in response to database transactions (INSERT, UPDATE, DELETE) on specified tables, schemas, or the entire database.  
Listening is done using Postgres's logical replication streaming protocol, ensuring efficient and low-latency triggering.  
Postgres triggers are not available on the [Cloud](/pricing).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/V50Jl4D_RTY"
	title="Postgres triggers"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>
