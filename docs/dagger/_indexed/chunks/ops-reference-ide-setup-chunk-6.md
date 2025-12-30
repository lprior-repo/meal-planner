---
doc_id: ops/reference/ide-setup
chunk_id: ops/reference/ide-setup#chunk-6
heading_path: ["ide-setup", "PHP"]
chunk_type: code
tokens: 36
summary: "Ensure your `composer."
---
Ensure your `composer.json` has a path configured to the generated `dagger/dagger` package:

```json
"repositories": [
  {
    "type": "path",
    "url": "./sdk"
  }
],
"require": {
  "dagger/dagger": "*@dev"
}
```
