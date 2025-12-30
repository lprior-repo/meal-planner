---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-15
heading_path: ["Rich display rendering", "Render all"]
chunk_type: prose
tokens: 61
summary: "Render all"
---

## Render all

The `render_all` key allows returning all results with their specific format.

```ts
return { "render_all": [ { "json": { "a": 1 } }, { "table-col": { "foo": [42, 8], "bar": [38, 12] }} ] }
```
![Rich display Render All](./render_all.png "Rich display Render All")
