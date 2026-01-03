---
doc_id: ref/moonrepo/project
chunk_id: ref/moonrepo/project#chunk-4
heading_path: ["Projects", "Dependencies"]
chunk_type: prose
tokens: 115
summary: "Dependencies"
---

## Dependencies

Projects can depend on other projects within the [workspace](/docs/concepts/workspace) to build a [project graph](/docs/how-it-works/action-graph), and in turn, an action graph for executing [tasks](/docs/concepts/task). Project dependencies are divided into 2 categories:

-   **Explicit dependencies** - These are dependencies that are explicitly defined in a project's [`moon.yml`](/docs/config/project) config file, using the [`dependsOn`](/docs/config/project#dependson) setting.
-   **Implicit dependencies** - These are dependencies that are implicitly discovered by moon when scanning the repository. How an implicit dependency is discovered is based on the project's [`language`](/docs/config/project#language) setting, and how that language's ecosystem functions.
