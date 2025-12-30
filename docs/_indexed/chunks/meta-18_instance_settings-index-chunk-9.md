---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-9
heading_path: ["Instance settings", "Indexer "]
chunk_type: prose
tokens: 357
summary: "Indexer "
---

## Indexer 

![Indexer](./indexer.png)

### Index writer memory budget 

The allocated memory arena for the indexer. A bigger value means less writing to disk and potentially higher indexing throughput

### Commit max batch size

The max amount of documents (here jobs) per commit. To optimize indexing throughput, it is best to keep this as high as possible. However, especially when reindexing the whole instance, it can be useful to have a limit on how many jobs can be written without being commited. A commit will make the jobs available for search, constitute a "checkpoint" state in the indexing and will be logged.

### Refresh index period

The index will query new jobs periodically and write them on the index. This setting sets that period in seconds.

### Max indexed job log size

Job logs are included when indexing, but to avoid the index size growing artificially, the logs will be truncated after that size (in KB) has been reached.

### Commit max batch size

The max amount of documents per commit. In this case 1 document is one log file representing all logs during 1 minute for a specific host. To optimize indexing throughput, it is best to keep this as high as possible. However, especially when reindexing the whole instance, it can be useful to have a limit on how many logs can be written without being commited. A commit will make the logs available for search, appear as a log line, and be a "checkpoint" of the indexing progress.

### Refresh index period

The index will query new service logs peridically and write them on the index. This setting sets that period in seconds.
