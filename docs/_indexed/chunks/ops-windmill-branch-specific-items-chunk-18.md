---
doc_id: ops/windmill/branch-specific-items
chunk_id: ops/windmill/branch-specific-items#chunk-18
heading_path: ["Branch-specific items", "Troubleshooting"]
chunk_type: prose
tokens: 136
summary: "Troubleshooting"
---

## Troubleshooting

### Files not being detected as branch-specific

**Problem**: Files you expect to be branch-specific are not being transformed.

**Solutions**:
1. **Check patterns**: Ensure your glob patterns match the file paths exactly
2. **Verify file types**: Only variables, resources, resource files, and trigger files are supported
3. **Pattern testing**: Use tools like [globtester.com](https://globtester.com) to test your patterns

### Files in wrong workspace

**Problem**: Branch-specific files are syncing to the wrong workspace.

**Solutions**:
1. **Check branch config**: Ensure your branch configuration is correct
2. **Verify current branch**: Make sure you're on the expected Git branch
3. **Configuration precedence**: Remember that CLI flags override branch settings
