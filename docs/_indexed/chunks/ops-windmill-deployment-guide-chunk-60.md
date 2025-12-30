---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-60
heading_path: ["Windmill Deployment Guide", "Check job details"]
chunk_type: prose
tokens: 83
summary: "Check job details"
---

## Check job details
wmill job get <job_id>
```text

**Resolution:**
1. Increase worker memory limits in docker-compose
2. Increase job timeout:
   ```yaml
   # In script metadata
   timeout: 600  # 10 minutes
   ```text
3. Optimize script to process data in chunks
4. Use dedicated workers for heavy jobs:
   ```yaml
   tag: heavy-compute
   ```yaml

---

### Issue: Secrets Not Accessible

**Symptoms:** "Permission denied" accessing secrets

**Diagnosis:**
```bash
