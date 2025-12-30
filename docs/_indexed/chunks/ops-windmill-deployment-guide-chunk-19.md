---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-19
heading_path: ["Windmill Deployment Guide", "Create PostgreSQL resource"]
chunk_type: prose
tokens: 39
summary: "Create PostgreSQL resource"
---

## Create PostgreSQL resource
wmill resource push - f/meal-planner/database/postgres <<EOF
{
  "host": "\$var:f/meal-planner/vars/db_host",
  "port": 5432,
  "user": "\$var:f/meal-planner/vars/db_user",
  "password": "\$var:f/meal-planner/vars/db_password",
  "dbname": "meal_planner",
  "sslmode": "prefer"
}
EOF
```text

### Tandoor API

```bash
