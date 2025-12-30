---
doc_id: ops/getting-started/types-cachevolume
chunk_id: ops/getting-started/types-cachevolume#chunk-1
heading_path: ["types-cachevolume"]
chunk_type: prose
tokens: 153
summary: "> **Context**: Volume caching involves caching specific parts of the filesystem and reusing them ..."
---
# CacheVolume

> **Context**: Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especial...


Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especially useful when dealing with package managers such as `npm`, `maven`, `pip` and similar. Since these dependencies are usually locked to specific versions in the application's manifest, re-downloading them on every session is inefficient and time-consuming.

The `CacheVolume` type represents a directory whose contents persist across Dagger sessions. By using a cache volume for dependencies, Dagger can reuse the cached contents across Dagger workflow runs and reduce execution time.
