---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-62
heading_path: ["Windmill Deployment Guide", "Check user permissions"]
chunk_type: prose
tokens: 71
summary: "Check user permissions"
---

## Check user permissions
wmill user whoami
```

**Resolution:**
1. Verify variable path permissions match user/group
2. Add user to appropriate group:
   ```bash
   wmill group add-user devops <username>
   ```
3. Update variable permissions:
   ```bash
   wmill variable update f/meal-planner/vars/db_password \
     --add-group g/devops
   ```

---

### Issue: Deployment Failed

**Symptoms:** `wmill sync push` shows errors

**Diagnosis:**
```bash
