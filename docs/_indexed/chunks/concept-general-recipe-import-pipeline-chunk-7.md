---
doc_id: concept/general/recipe-import-pipeline
chunk_id: concept/general/recipe-import-pipeline#chunk-7
heading_path: ["Recipe Import Pipeline", "Error Handling"]
chunk_type: prose
tokens: 40
summary: "Error Handling"
---

## Error Handling

- Invalid URL → fail step, log, continue
- API timeout → retry with backoff
- Missing nutrition → warn, use defaults
- Duplicate recipe → skip, log
