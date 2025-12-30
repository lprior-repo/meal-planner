---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-27
heading_path: ["Windmill Deployment Guide", "FatSecret configuration"]
chunk_type: prose
tokens: 45
summary: "FatSecret configuration"
---

## FatSecret configuration
wmill variable add f/meal-planner/vars/fatsecret_key --value="your_key" --secret
wmill variable add f/meal-planner/vars/fatsecret_secret --value="your_secret" --secret
wmill variable add f/meal-planner/vars/oauth_encryption_key --value="your_64_hex_key" --secret
```

### Environment-Specific Variables

Use branch-specific items or separate workspaces for different environments:

```bash
