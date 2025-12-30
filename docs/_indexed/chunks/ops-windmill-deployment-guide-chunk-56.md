---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-56
heading_path: ["Windmill Deployment Guide", "Test connection manually"]
chunk_type: code
tokens: 158
summary: "Test connection manually"
---

## Test connection manually
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1"
```text

**Resolution:**
1. Check variable values are correct
2. Verify network connectivity (firewall, security groups)
3. Check credentials haven't expired
4. Update resource with correct values:
   ```bash
   wmill variable update f/meal-planner/vars/db_password --value="new_password"
   ```yaml

---

### Issue: OAuth Token Expired

**Symptoms:** "401 Unauthorized" from FatSecret API

**Diagnosis:**
```sql
SELECT user_id, provider, expires_at
FROM oauth_tokens
WHERE provider = 'fatsecret'
  AND expires_at < NOW();
```text

**Resolution:**
1. Trigger token refresh flow
2. If refresh fails, prompt user to re-authorize
3. Clear expired tokens:
   ```sql
   DELETE FROM oauth_tokens
   WHERE expires_at < NOW() - INTERVAL '30 days';
   ```yaml

---

### Issue: Schedule Not Running

**Symptoms:** Scheduled job shows no recent runs

**Diagnosis:**
```bash
