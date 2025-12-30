---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-21
heading_path: ["Windmill Deployment Guide", "Create FatSecret OAuth resource"]
chunk_type: prose
tokens: 32
summary: "Create FatSecret OAuth resource"
---

## Create FatSecret OAuth resource
wmill resource push - f/meal-planner/external_apis/fatsecret <<EOF
{
  "consumer_key": "\$var:f/meal-planner/vars/fatsecret_key",
  "consumer_secret": "\$var:f/meal-planner/vars/fatsecret_secret",
  "encryption_key": "\$var:f/meal-planner/vars/oauth_encryption_key"
}
EOF
```

### Verify Resources

```bash
