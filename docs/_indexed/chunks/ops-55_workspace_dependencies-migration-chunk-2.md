---
doc_id: ops/55_workspace_dependencies/migration
chunk_id: ops/55_workspace_dependencies/migration#chunk-2
heading_path: ["Migration guide", "Migration steps"]
chunk_type: prose
tokens: 115
summary: "Migration steps"
---

## Migration steps

### 1. Resolve conflicts

If you have a `/dependencies` folder at the workspace root, rename it. The workspace root `/dependencies` path is reserved for the new system.

Note: Folders like `/f/dependencies` or `/u/username/dependencies` are not affected.

### 2. Move dependency files

Move all your requirements.txt, package.json, composer.json files to the workspace `/dependencies` directory:

- `requirements.txt` → `/dependencies/<name>.requirements.in`
- `package.json` → `/dependencies/<name>.package.json`
- `composer.json` → `/dependencies/<name>.composer.json`

Choose descriptive names like `ml.requirements.in` or `api.package.json`.

### 3. Update scripts

Add annotations to scripts that should use workspace dependencies:

```python
