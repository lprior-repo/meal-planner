---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-20
heading_path: ["Windmill Deployment Guide", "Create Tandoor resource"]
chunk_type: prose
tokens: 28
summary: "Create Tandoor resource"
---

## Create Tandoor resource
wmill resource push - f/meal-planner/external_apis/tandoor <<EOF
{
  "base_url": "\$var:f/meal-planner/vars/tandoor_url",
  "api_token": "\$var:f/meal-planner/vars/tandoor_token"
}
EOF
```text

### FatSecret API

```bash
