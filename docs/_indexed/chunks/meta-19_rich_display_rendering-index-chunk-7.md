---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-7
heading_path: ["Rich display rendering", "PDF"]
chunk_type: code
tokens: 55
summary: "PDF"
---

## PDF

The `pdf` key allows returning the value as a PDF.

The PDF must be encoded in base64.

```ts
return { "pdf": { "content": base64Pdf } }
```

or

```ts
return { "pdf": base64Pdf }
```


![Rich display PDF](./pdf.png "Rich display PDF")
