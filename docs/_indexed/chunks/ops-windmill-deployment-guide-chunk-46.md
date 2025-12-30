---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-46
heading_path: ["Windmill Deployment Guide", "Using psql directly"]
chunk_type: prose
tokens: 18
summary: "Using psql directly"
---

## Using psql directly
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME \
  -f src/db/migrations/002_add_oauth_tokens.sql
