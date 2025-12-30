---
doc_id: tutorial/reference/configuration-cache
chunk_id: tutorial/reference/configuration-cache#chunk-3
heading_path: ["configuration-cache", "Garbage Collection"]
chunk_type: prose
tokens: 86
summary: "The cache garbage collector runs in the background, looking for unused layers and artifacts, and ..."
---
The cache garbage collector runs in the background, looking for unused layers and artifacts, and clears them up once they exceed the storage allowed by the cache policy.

The default cache policy attempts to keep the long-term cache storage under 75% of the total disk, while ensuring at least 20% of the disk remains free.

The cache policy can be manually configured using the engine config.
