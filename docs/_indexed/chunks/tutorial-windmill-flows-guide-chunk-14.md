---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-14
heading_path: ["Windmill Flows Guide", "Common Issues"]
chunk_type: prose
tokens: 74
summary: "Common Issues"
---

## Common Issues

### "ENOTDIR" on flow push
Use directory path, not file path. See Quick Reference above.

### Flow not syncing with `wmill sync push`
Flows may not auto-sync. Use `wmill flow push` explicitly.

### Suspended flow blocking CLI
Run flows via API with async, or use Windmill UI. CLI waits forever on suspended flows.

```bash
