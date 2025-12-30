---
doc_id: meta/36_service_logs/index
chunk_id: meta/36_service_logs/index#chunk-2
heading_path: ["Service logs", "Log search"]
chunk_type: prose
tokens: 351
summary: "Log search"
---

## Log search

:::info
Full text search is a feature available in Windmill EE, however, note that it is disabled by default in the example docker compose. To enable full text search on logs and completed jobs, you need to spin up the indexer service, [learn how to](../../misc/18_full_text_search/index.mdx).
:::

You can type any string on the search bar to query logs, the hosts that matched your query will be shown on the left pane with the count of lines that matched the query.

If you select a host, you will get the most recent lines that match your query (limited to 1000). This is very similar to what you would expect from a graphana setup.

![Search results](./service_log_search_results.png)


Queries are parsed by Tantivy's [QueryParser](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html), which lets you build relatively complex and useful queries. For example, you can try searching:

```
worker_group:default ping
```
To limit the search to workers in the default worker group.

The fields that are indexed and can be used for this kind of search are:

| Filed name  | Type | Description |
| ----------- | ---- | ----------- |
|host         | TEXT | The hostname, e.g windmill-workers-7cbf97c994-lptqj |
|mode         | TEXT | The mode, `worker`, `server` or `indexer` |
|worker_group | TEXT | Worker Group associated (if applicable) |
|timestamp    | DATE | This is the timestamp of the log file used to store the logs internally, meaning that it's innacurate of up to a minute. |
|file_name    | TEXT | Name of the file associated in s3 or in disk. |
|logs         | TEXT | the log lines themselves. `logs:<query>` is equivalent to `query` |
