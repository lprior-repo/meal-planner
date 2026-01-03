---
doc_id: tutorial/windmill/ducklake
chunk_id: tutorial/windmill/ducklake#chunk-4
heading_path: ["Ducklake", "DuckDB example"]
chunk_type: prose
tokens: 222
summary: "DuckDB example"
---

## DuckDB example

DuckDB is the native query engine for Ducklake. Other integrations (TypeScript, Python...) run DuckDB scripts under the hood.
Note that these integrations do not start a new job when running the queries. The DuckDB script is run inline within the same worker.

In the example below, we pass a list of messages with positive, neutral or negative sentiment.  
This list might come from a Python script which queries new reviews from the Google My Business API,
and sends them to an LLM to determine their sentiment.  
The messages are then inserted into a Ducklake table, which effectively creates a new parquet file and stores metadata in the catalog.

```sql
-- $messages (json[])

ATTACH 'ducklake://main' AS dl;
USE dl;

CREATE TABLE IF NOT EXISTS messages (
  content STRING NOT NULL,
  author STRING NOT NULL,
  date STRING NOT NULL,
  sentiment STRING
);

CREATE TEMP TABLE new_messages AS
  SELECT
    value->>'content' AS content,
    value->>'author' AS author,
    value->>'date' AS date,
    value->>'sentiment' AS sentiment
  FROM json_each($messages);

INSERT INTO messages
  SELECT * FROM new_messages;
```
