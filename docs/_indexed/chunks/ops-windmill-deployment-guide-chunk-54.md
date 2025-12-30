---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-54
heading_path: ["Windmill Deployment Guide", "Check job queue"]
chunk_type: prose
tokens: 66
summary: "Check job queue"
---

## Check job queue
wmill job list --status=queued
```text

**Resolution:**
1. Verify workers are running: `docker ps | grep windmill-worker`
2. Check worker logs: `docker logs windmill-worker-1`
3. Restart workers if needed: `docker-compose restart windmill-worker`

---

### Issue: Resource Connection Failed

**Symptoms:** "Failed to connect to database" or similar

**Diagnosis:**
```bash
