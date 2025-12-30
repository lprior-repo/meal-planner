---
doc_id: meta/32_private_hub/index
chunk_id: meta/32_private_hub/index#chunk-4
heading_path: ["Private Hub", "Hub scripts search and embeddings"]
chunk_type: prose
tokens: 165
summary: "Hub scripts search and embeddings"
---

## Hub scripts search and embeddings

The search on your private hub and on your Windmill instance is powered by vector search.
Vector search requires embeddings of the hub scripts which are computed by your private hub every hour. 
Your Windmill instance then fetches those embeddings once a day and uses them for search in the app.

You can modify the embeddings computation and the embeddings retrieval frequencies.

- To update the embedding computation frequency, set the environment variable `EMBEDDINGS_REFRESH_INTERVAL_SECS` on your Hub server. We do not recommend setting this value to less than 3600 seconds, as it can be resource-intensive, especially for large hubs.
- To update the frequency of embedding retrieval, set the environment variable `HUB_EMBEDDINGS_PULLING_INTERVAL_SECS` on your Windmill server(s).


Both values are in seconds.
