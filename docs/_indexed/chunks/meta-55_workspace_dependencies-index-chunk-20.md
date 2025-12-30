---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-20
heading_path: ["Workspace dependencies", "Common patterns"]
chunk_type: code
tokens: 100
summary: "Common patterns"
---

## Common patterns

### Team-based dependencies
```
/dependencies/
├── frontend.package.json      # Frontend team deps
├── backend.package.json       # Backend team deps
├── data.requirements.in       # Data team deps
└── shared.requirements.in     # Common dependencies
```

### Environment-based
```
/dependencies/
├── prod.requirements.in       # Production-ready versions
├── dev.requirements.in        # Development dependencies
└── test.requirements.in       # Testing utilities
```

### Feature-based
```
/dependencies/
├── ml.requirements.in         # Machine learning
├── api.requirements.in        # API integrations
├── ui.package.json           # UI components
└── data.requirements.in       # Data processing
```
