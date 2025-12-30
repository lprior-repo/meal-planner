---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-12
heading_path: ["Rich display rendering", "Error"]
chunk_type: prose
tokens: 48
summary: "Error"
---

## Error

The `error` key allows returning the value as an error message.

```ts
return { "error": { "name": "418", "message": "I'm a teapot", "stack": "Error: I'm a teapot" }}
```

![Rich display Error](./error.png "Rich display Error")
