---
doc_id: ops/query/projects
chunk_id: ops/query/projects#chunk-6
heading_path: ["query projects", "Find all affected projects using the results of another query"]
chunk_type: prose
tokens: 252
summary: "Find all affected projects using the results of another query"
---

## Find all affected projects using the results of another query
$ moon query touched-files | moon query projects --affected
```

### Arguments

- `[query]` - An optional [query statement](/docs/concepts/query-lang) to filter projects with. When provided, all [filter options](#filters) are ignored. v1.4.0

### Options

- `--json` - Display the projects in JSON format.

#### Affected

- `--affected` - Filter projects that have been affected by touched files.
- `--downstream` - Include downstream dependents of queried projects. Supports "none" (default), "direct", "deep". v1.29.0
- `--upstream` - Include upstream dependencies of queried projects. Supports "none", "direct", "deep" (default). v1.29.0

#### Filters

All option values are case-insensitive regex patterns.

- `--alias <regex>` - Filter projects that match this alias.
- `--id <regex>` - Filter projects that match this ID/name.
- `--language <regex>` - Filter projects of this programming language.
- `--layer <regex>` - Filter project of this layer.
- `--source <regex>` - Filter projects that match this source path.
- `--stack <regex>` - Filter projects of the tech stack.
- `--tags <regex>` - Filter projects that have the following tags.
- `--tasks <regex>` - Filter projects that have the following tasks.

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
