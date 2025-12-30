---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-9
heading_path: ["Rich display rendering", "JPEG"]
chunk_type: code
tokens: 57
summary: "JPEG"
---

## JPEG

The `jpeg` key allows returning the value as a JPEG image.

The picture must be encoded in base64.

```ts
return { "jpeg": { "content": base64Image } }
```

or

```ts
return { "jpeg": base64Image }
```

![Rich display JPEG](./jpeg.png "Rich display JPEG")
