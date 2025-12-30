---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-6
heading_path: ["Rich display rendering", "File"]
chunk_type: prose
tokens: 40
summary: "File"
---

## File

The `file` key allows returning an option to download a file.

```ts
return { "file": { "content": encode(file), "filename": "data.txt" } }
```

![Rich display File](./file.png "Rich display File")
