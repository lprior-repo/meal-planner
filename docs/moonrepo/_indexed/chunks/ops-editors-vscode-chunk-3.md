---
doc_id: ops/editors/vscode
chunk_id: ops/editors/vscode#chunk-3
heading_path: ["VS Code extension", "Features"]
chunk_type: prose
tokens: 71
summary: "Features"
---

## Features

### YAML validation

To enable accurate validation of our YAML configuration files, you'll need to update the `yaml.schemas` setting in `.vscode/settings.json` to point to the local schemas at `.moon/cache/schemas`.

This can be automated by running the "moon: Append YAML schemas configuration to settings" in the command palette, after the extension has been installed.
