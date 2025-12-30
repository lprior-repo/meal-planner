---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-30
heading_path: ["Windmill Deployment Guide", "Production"]
chunk_type: prose
tokens: 27
summary: "Production"
---

## Production
wmill workspace switch meal-planner-prod
wmill variable add f/meal-planner/vars/environment --value="production"
```

### Accessing Variables in Scripts

**Python:**
```python
import wmill
