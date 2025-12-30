---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-25
heading_path: ["Windmill Deployment Guide", "Database configuration"]
chunk_type: prose
tokens: 24
summary: "Database configuration"
---

## Database configuration
wmill variable add f/meal-planner/vars/db_host --value="localhost"
wmill variable add f/meal-planner/vars/db_user --value="postgres"
wmill variable add f/meal-planner/vars/db_password --value="your_password" --secret
