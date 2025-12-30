---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-6
heading_path: ["Windmill Flows Guide", "Flow File Structure"]
chunk_type: code
tokens: 33
summary: "Flow File Structure"
---

## Flow File Structure

```
windmill/f/<domain>/<flow_name>.flow/
└── flow.yaml    # Flow definition
```text

**Important**: When pushing flows, use the `.flow` directory path, NOT the `flow.yaml` file:
```bash
