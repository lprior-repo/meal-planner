---
doc_id: ref/concepts/task
chunk_id: ref/concepts/task#chunk-3
heading_path: ["Tasks", "Types"]
chunk_type: prose
tokens: 100
summary: "Types"
---

## Types

Tasks are grouped into 1 of the following types based on their configured parameters.

-   **Build** - Task generates one or many artifacts, and is derived from the [`outputs`](/docs/config/project#outputs) setting.
-   **Run** - Task runs a one-off, long-running, or never-ending process, and is derived from the [`local`](/docs/config/project#local) setting.
-   **Test** - Task asserts code is correct and behaves as expected. This includes linting, typechecking, unit tests, and any other form of testing. Is the default.
