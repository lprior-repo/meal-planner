---
doc_id: ref/moonrepo/project
chunk_id: ref/moonrepo/project#chunk-3
heading_path: ["Projects", "Aliases"]
chunk_type: prose
tokens: 159
summary: "Aliases"
---

## Aliases

Aliases are a secondary approach for naming projects, and can be used as a drop-in replacement for standard names. What this means is that an alias can also be used when configuring dependencies, or defining [targets](/docs/concepts/target).

However, the difference between aliases and names is that aliases *can not* be explicit configured in moon. Instead, they are specific to a project's primary programming language, and are inferred based on that context (when enabled in settings). For example, a JavaScript or TypeScript project will use the `name` field from its `package.json` as the alias.

Because of this, a project can either be referenced by its name or alias, or both. Choose the pattern that makes the most sense for your company or team!
