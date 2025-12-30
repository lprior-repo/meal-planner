---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-59
heading_path: ["Windmill Deployment Guide", "Pull first to see remote changes"]
chunk_type: prose
tokens: 79
summary: "Pull first to see remote changes"
---

## Pull first to see remote changes
wmill sync pull --show-diffs
```text

**Resolution:**
1. Review conflicts in diff output
2. Decide which version to keep
3. Use `--yes` to force push (destructive):
   ```bash
   wmill sync push --yes
   ```text
4. Or merge changes manually and push

---

### Issue: Memory/Timeout Errors

**Symptoms:** Job fails with "out of memory" or "timeout"

**Diagnosis:**
```bash
