---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-10
heading_path: ["Windmill Flows Guide", "Input Transforms"]
chunk_type: code
tokens: 66
summary: "Input Transforms"
---

## Input Transforms

### Static Value
```yaml
input_transforms:
  param:
    type: static
    value: 'hardcoded_value'
```bash

### Resource Reference
```yaml
input_transforms:
  config:
    type: static
    value: '$res:u/admin/my_resource'
```text

### From Previous Step
```yaml
input_transforms:
  data:
    type: javascript
    expr: results.a.some_field
```text

### From Resume Payload (approval flows)
```yaml
input_transforms:
  verifier:
    type: javascript
    expr: resume.verifier
```text
