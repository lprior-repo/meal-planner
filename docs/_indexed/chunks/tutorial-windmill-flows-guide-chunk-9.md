---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-9
heading_path: ["Windmill Flows Guide", "Flow YAML Structure"]
chunk_type: prose
tokens: 55
summary: "Flow YAML Structure"
---

## Flow YAML Structure

```yaml
summary: Flow Name
description: What it does
value:
  modules:
    - id: a
      summary: Step description
      value:
        type: script
        path: f/domain/script_name
        input_transforms:
          param:
            type: static
            value: '$res:u/admin/resource_name'
  same_worker: false
schema:
  $schema: 'https://json-schema.org/draft/2020-12/schema'
  type: object
  properties: {}
  required: []
```text
