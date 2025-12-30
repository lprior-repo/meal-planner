---
doc_id: ops/3_cli/branch-specific-items
chunk_id: ops/3_cli/branch-specific-items#chunk-17
heading_path: ["Branch-specific items", "Best practices"]
chunk_type: prose
tokens: 107
summary: "Best practices"
---

## Best practices

### Configuration patterns

- **Start broad**: Use `commonSpecificItems` for widely-used resources
- **Be specific**: Target exact paths rather than overly broad patterns
- **Group logically**: Organize patterns by team, environment, or function

### Team workflows

1. **Define patterns early**: Establish branch-specific patterns before team members start using them
2. **Document conventions**: Make clear which resources should be branch-specific
3. **Review warnings**: Pay attention to CLI warnings about unsafe characters
4. **Test locally**: Verify branch-specific behavior works correctly before CI/CD integration
