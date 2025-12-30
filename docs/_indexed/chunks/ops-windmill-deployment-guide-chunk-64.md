---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-64
heading_path: ["Windmill Deployment Guide", "Validate flow YAML"]
chunk_type: prose
tokens: 46
summary: "Validate flow YAML"
---

## Validate flow YAML
wmill flow validate f/meal-planner/workflows/main.flow.yaml
```

**Resolution:**
1. Fix syntax errors in scripts
2. Regenerate metadata:
   ```bash
   wmill script generate-metadata
   wmill flow generate-locks
   ```
3. Push again:
   ```bash
   wmill sync push
   ```

---
