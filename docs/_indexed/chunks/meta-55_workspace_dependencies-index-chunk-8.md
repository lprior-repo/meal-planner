---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-8
heading_path: ["Workspace dependencies", "Supported languages and features"]
chunk_type: prose
tokens: 140
summary: "Supported languages and features"
---

## Supported languages and features

| Language | Syntax | Extra implicit | Manual implicit | Manual explicit | Extra explicit | 
|----------|--------|----------------|-----------------|-----------------|----------------|
| Python   | `# (extra_)requirements:` | ❌ | ✅ | one external or less or inline | inline only | 
| TypeScript (Bun) | `// (extra_)package_json:` | ❌ | ✅ | one external or less | ❌ |
| PHP      | `// (extra_)composer_json:` | ❌ | ✅ | one external or less | ❌ |
| Go       | `// (extra_)go_mod:` | ❌ | ❌ | ❌ | ❌ |

Note: Go support not yet available. Extra requirements mode (`#extra_requirements:`, etc.) is planned for future releases.
