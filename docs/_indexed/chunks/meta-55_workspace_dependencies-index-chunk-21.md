---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-21
heading_path: ["Workspace dependencies", "Troubleshooting"]
chunk_type: prose
tokens: 211
summary: "Troubleshooting"
---

## Troubleshooting

### Missing dependencies
- Check annotation syntax: `# requirements: filename`
- Verify file exists in workspace `/dependencies`
- Ensure file contains required packages

### Annotation conflicts
- Use either `# requirements:` OR `# extra_requirements:`, not both
- `# requirements:` takes precedence if both present

### CLI problems
- Upgrade to latest Windmill CLI
- Ensure admin permissions for dependency management
- Check dependency file format validity

### Import errors
- Requirements mode disables import inference
- Add missing packages to dependency files
- Consider switching to extra mode if you want inference + workspace deps

For debugging, generate and inspect lockfiles:
```bash
wmill script generate-metadata script_path
cat script_path.lock
```

:::info
Workspace dependencies replace the previous "raw requirements" system. See [migration guide](./ops-55_workspace_dependencies-migration.md) if upgrading from the old system.
:::

<div className="grid grid-cols-2 gap-6 mb-4">
  <DocCard
    title="Migration guide"
    description="Migrate from the previous dependency system to workspace dependencies."
    href="/docs/core_concepts/workspace_dependencies/migration"
  />
  <DocCard
    title="Dependency management overview" 
    description="Understanding Windmill's dependency resolution and import system."
    href="/docs/advanced/imports"
  />
</div>
