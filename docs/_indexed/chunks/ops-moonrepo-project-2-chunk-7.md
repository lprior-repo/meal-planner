---
doc_id: ops/moonrepo/project-2
chunk_id: ops/moonrepo/project-2#chunk-7
heading_path: ["moon.{pkl,yml}", "`layer`"]
chunk_type: prose
tokens: 146
summary: "`layer`"
---

## `layer`

> This was previously known as `type` and was renamed to `layer` in v1.39.

The layer within a [stack](#stack). Supports the following values:

-   `application` - An application of any kind.
-   `automation` - An automated testing suite, like E2E, integration, or visual tests. (v1.16.0)
-   `configuration` - Configuration files or infrastructure. (v1.22.0)
-   `library` - A self-contained, shareable, and publishable set of code.
-   `scaffolding` - Templates or generators for scaffolding. (v1.22.0)
-   `tool` - An internal tool, CLI, one-off script, etc.
-   `unknown` (default) - When not configured.

moon.yml

```yaml
layer: 'application'
```

> The project layer is used in [task inheritance](/docs/concepts/task-inheritance), [constraints and boundaries](/docs/config/workspace#constraints), editor extensions, and more!
