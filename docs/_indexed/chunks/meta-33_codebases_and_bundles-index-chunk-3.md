---
doc_id: meta/33_codebases_and_bundles/index
chunk_id: meta/33_codebases_and_bundles/index#chunk-3
heading_path: ["Codebases & bundles", "wmill.yaml"]
chunk_type: prose
tokens: 57
summary: "wmill.yaml"
---

## wmill.yaml

Here are the changes needed in your [`wmill.yaml`](https://github.com/windmill-labs/windmill-codebase-example/blob/main/windmill/wmill.yaml):

```yaml
---
codebases:
  - relative_path: ../codebase
    includes:
      - '**'
    excludes: []
```

Windmill keeps track of the hash of the codebase and will only rebuild the bundle if the codebase or script has changed.
