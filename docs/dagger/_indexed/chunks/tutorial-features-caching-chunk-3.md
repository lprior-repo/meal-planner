---
doc_id: tutorial/features/caching
chunk_id: tutorial/features/caching#chunk-3
heading_path: ["caching", "Volume caching"]
chunk_type: prose
tokens: 131
summary: "Volume caching involves caching specific parts of the filesystem and reusing them on subsequent f..."
---
Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especially useful when dealing with package managers such as `npm`, `maven`, `pip` and similar. Since these dependencies are usually locked to specific versions in the application's manifest, re-downloading them on every session is inefficient and time-consuming.

> **Info:** For these tools to cache properly, they need their own cache data (usually a directory) to be persisted between sessions. By using a cache volume for this data, Dagger can reuse the cached contents across workflow runs and reduce execution time.
