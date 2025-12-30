---
doc_id: ops/3_cli/branch-specific-items
chunk_id: ops/3_cli/branch-specific-items#chunk-4
heading_path: ["Branch-specific items", "Branch name safety"]
chunk_type: prose
tokens: 105
summary: "Branch name safety"
---

## Branch name safety

Branch names containing certain characters are automatically sanitized for filesystem safety:

- **Unsafe characters**: `/ \ : * ? " < > | .`
- **Replacement**: All unsafe characters are replaced with `_`
- **Warning**: The CLI shows a clear warning when sanitization occurs

```bash
Warning: Branch name "feature/api-v2.1" contains filesystem-unsafe characters (/ \ : * ? " < > | .)
and was sanitized to "feature_api-v2_1". This may cause collisions with other similarly named branches.
```
