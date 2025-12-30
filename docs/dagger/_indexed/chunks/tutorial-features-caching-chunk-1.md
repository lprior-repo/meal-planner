---
doc_id: tutorial/features/caching
chunk_id: tutorial/features/caching#chunk-1
heading_path: ["caching"]
chunk_type: prose
tokens: 164
summary: "> **Context**: One of Dagger's most powerful features is its speed, by virtue of its ability to c..."
---
# Built-In Caching

> **Context**: One of Dagger's most powerful features is its speed, by virtue of its ability to cache data across workflow runs.


One of Dagger's most powerful features is its speed, by virtue of its ability to cache data across workflow runs.

Dagger caches several types of data:

1. **Layers**: This refers to build instructions and the results of some API calls, such as those that modify files and directories.
2. **Volumes**: This refers to the contents of a Dagger filesystem volume and is persisted across Dagger Engine sessions.
3. **Function Calls**: This refers to the values returned by calling a function in a module. Execution of the function call may be skipped when there is a cached result for the function call.
