---
doc_id: ops/reference/ide-setup
chunk_id: ops/reference/ide-setup#chunk-5
heading_path: ["ide-setup", "TypeScript"]
chunk_type: code
tokens: 36
summary: "For Dagger modules initialized using `dagger init`, the default template is already configured wi..."
---
For Dagger modules initialized using `dagger init`, the default template is already configured with the correct `tsconfig.json`:

```json
{
    "experimentalDecorators": true,
    "paths": {
      "@dagger.io/dagger": ["./sdk"]
    }
}
```
