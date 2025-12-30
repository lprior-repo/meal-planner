---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-3
heading_path: ["Workspace dependencies", "Dependency files location"]
chunk_type: prose
tokens: 113
summary: "Dependency files location"
---

## Dependency files location

Locally all dependency files are stored under `/dependencies` in your workspace:

```
/dependencies/
├── ml.requirements.in          # Named Python dependencies
├── api.package.json            # Named TypeScript dependencies  
├── web.composer.json           # Named PHP dependencies
├── requirements.in             # Python default (requirements mode)
├── extra.requirements.in       # Python default (extra mode)
└── package.json                # TypeScript default
```

**Naming rules**:
- Named files: `<name>.<extension>` (e.g., `ml.requirements.in`)
- Unnamed defaults: `<extension>` or `extra.<extension>`
- Cannot use `default` as a filename
- One unnamed default per language (either standard OR `extra.` form)
