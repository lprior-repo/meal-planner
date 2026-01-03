---
doc_id: ops/windmill/branch-specific-items
chunk_id: ops/windmill/branch-specific-items#chunk-2
heading_path: ["Branch-specific items", "How branch-specific items work"]
chunk_type: prose
tokens: 88
summary: "How branch-specific items work"
---

## How branch-specific items work

When a file is marked as branch-specific through pattern matching in your `wmill.yaml` configuration, the CLI automatically transforms the file path based on the current Git branch:

- **Local files**: Use branch-suffixed names (e.g., `database.main.resource.yaml`)
- **Windmill workspace**: Uses clean base paths (e.g., `database.resource.yaml`)

This allows different branches to have different configurations for the same logical resource while keeping the workspace paths clean.
