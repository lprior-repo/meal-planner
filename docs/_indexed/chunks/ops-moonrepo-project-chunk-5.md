---
doc_id: ops/moonrepo/project
chunk_id: ops/moonrepo/project#chunk-5
heading_path: ["project", "`language`"]
chunk_type: prose
tokens: 153
summary: "`language`"
---

## `language`

The primary programming language the project is written in. This setting is required for [task inheritance](/docs/config/tasks), editor extensions, and more. Supports the following values:

-   `bash` - A Bash based project (Unix only).
-   `batch` - A Batch/PowerShell based project (Windows only).
-   `go` - A Go based project.
-   `javascript` - A JavaScript based project.
-   `php` - A PHP based project.
-   `python` - A Python based project.
-   `ruby` - A Ruby based project.
-   `rust` - A Rust based project.
-   `typescript` - A TypeScript based project.
-   `unknown` (default) - When not configured or inferred.
-   `*` - A custom language. Values will be converted to kebab-case.

moon.yml

```yaml
language: 'javascript'
