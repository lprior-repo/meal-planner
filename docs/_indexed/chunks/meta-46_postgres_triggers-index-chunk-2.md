---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-2
heading_path: ["Postgres triggers", "What is logical replication?"]
chunk_type: prose
tokens: 201
summary: "What is logical replication?"
---

## What is logical replication?

Windmill's Postgres trigger feature is built on Postgres's logical replication protocol, which allows changes to a database to be streamed in real time to subscribers. Logical replication provides fine-grained control over what data is replicated by allowing the user to define publications and subscribe to specific changes.

### How logical replication works
1. **Publications**: Define what changes (e.g., INSERT, UPDATE, DELETE) should be made available for replication. Publications allow you to select specific tables or schemas to track.
2. **Replication slots**: Ensure that all changes from a publication are retained until they are successfully delivered to the subscriber (e.g., Windmill triggers). This guarantees data reliability and prevents data loss.

Windmill uses logical replication to efficiently stream database changes to your configured triggers, ensuring minimal latency and high reliability.

For more details, see the [Postgres documentation on logical replication](https://www.postgresql.org/docs/current/logical-replication.html).  
For more details, see the [Postgres documentation on logical replication streaming protocol](https://www.postgresql.org/docs/current/protocol-logical-replication.html).
