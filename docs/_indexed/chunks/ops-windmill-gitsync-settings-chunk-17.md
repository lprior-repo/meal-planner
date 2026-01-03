---
doc_id: ops/windmill/gitsync-settings
chunk_id: ops/windmill/gitsync-settings#chunk-17
heading_path: ["Git sync settings", "Push promotion settings to workspace"]
chunk_type: prose
tokens: 61
summary: "Push promotion settings to workspace"
---

## Push promotion settings to workspace
wmill gitsync-settings push --promotion production
```

When using the `--promotion` flag, the command will use `promotionOverrides` instead of regular `overrides` from the specified branch in your `wmill.yaml`. This should be used when your git sync connection is configured in [promotion mode](./meta-windmill-index-2.md#promotion-mode).
