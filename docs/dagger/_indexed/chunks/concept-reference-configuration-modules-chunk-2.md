---
doc_id: concept/reference/configuration-modules
chunk_id: concept/reference/configuration-modules#chunk-2
heading_path: ["configuration-modules", "File and Directory Filters"]
chunk_type: code
tokens: 32
summary: "The `dagger."
---
The `dagger.json` supports an `include` field to specify additional files to include or exclude when loading the module.

```json
{
  "include": ["!.venv", "!node_modules"]
}
```
