---
doc_id: tutorial/reference/best-practices-monorepos
chunk_id: tutorial/reference/best-practices-monorepos#chunk-2
heading_path: ["best-practices-monorepos", "Top-level Dagger Module"]
chunk_type: prose
tokens: 116
summary: "Create a top-level Dagger module for the monorepo, attach sub-modules for each component, and mod..."
---
Create a top-level Dagger module for the monorepo, attach sub-modules for each component, and model the Dagger module dependencies on the logical dependencies between components.

This pattern is suitable when there are dependencies but differences between the projects (e.g., SDKs, CLIs, web applications, docs with different requirements).

### Benefits

- **Easier debugging**: Sub-modules provide a way to separate and debug business logic for different workflows
- **Code reuse**: Sub-modules in different projects can import each other
- **Improved performance**: The top-level module can orchestrate sub-modules using native concurrency features
