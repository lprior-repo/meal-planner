---
doc_id: meta/36_service_logs/index
chunk_id: meta/36_service_logs/index#chunk-1
heading_path: ["Service logs"]
chunk_type: prose
tokens: 240
summary: "Service logs"
---

# Service logs

> **Context**: View logs from any [workers](./meta-9_worker_groups-index.md) or servers directly within the service logs section of the [search modal](../35_search_bar/

View logs from any [workers](../9_worker_groups/index.mdx) or servers directly within the service logs section of the [search modal](./meta-35_search_bar-index.md).

![Service logs](./service_logs.png "Service logs")


Windmill provides direct access to the logs emitted by containers, removing the need to manually retrieve them from Docker or other container platforms. This enables monitoring services without needing to leave the Windmill environment.

You can view them from the [Workers](./meta-9_worker_groups-index.md) page, in particular:

- **Real-Time Monitoring**: While logs are emitted continuously, there is a 1-minute latency before they appear in the interface.
- **Visual Graphs**: You can easily track the number of logs and errors over time, displayed in a graphical interface:
  - **Log Count**: Displayed in the mini-graph, showing how many logs were generated each minute.
  - **Error Count**: Displayed in red, highlighting errors separately for quick identification.
- **Separation by Type**: Logs are organized by type. You can see logs for workers, servers and indexers.


On the left menu, you can navigate to Service logs.

![Service Logs On Menu](./service_logs_menu.png)
