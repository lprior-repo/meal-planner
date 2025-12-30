---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-8
heading_path: ["Rich display rendering", "PNG"]
chunk_type: code
tokens: 57
summary: "PNG"
---

## PNG

The `png` key allows returning the value as a PNG image.

The picture must be encoded in base64.

```ts
return { "png": { "content": base64Image } }
```

or

```ts
return { "png": base64Image }
```

![Rich display PNG](./png.png "Rich display PNG")
