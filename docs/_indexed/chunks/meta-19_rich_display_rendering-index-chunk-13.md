---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-13
heading_path: ["Rich display rendering", "Resume"]
chunk_type: prose
tokens: 44
summary: "Resume"
---

## Resume

The `resume` key allows returning an [approval](./tutorial-flows-11-flow-approval.md) and buttons to Resume or Cancel the step.

```ts
return { "resume": "https://example.com", "cancel": "https://example.com", "approvalPage": "https://example.com" }
```

![Rich display Resume](./approval.png "Rich display Resume")
