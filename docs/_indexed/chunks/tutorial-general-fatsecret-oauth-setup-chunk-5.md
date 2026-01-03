---
doc_id: tutorial/general/fatsecret-oauth-setup
chunk_id: tutorial/general/fatsecret-oauth-setup#chunk-5
heading_path: ["FatSecret OAuth Setup (One-Time)", "Step 4: Store in Windmill"]
chunk_type: prose
tokens: 58
summary: "Step 4: Store in Windmill"
---

## Step 4: Store in Windmill

```bash
TOKEN=$(grep -oP '"token":"\K[^"]+' ~/.config/windmill/remotes.ndjson)

curl -s -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "u/admin/fatsecret_oauth",
    "resource_type": "fatsecret",
    "value": {
      "consumer_key": "YOUR_KEY",
      "consumer_secret": "YOUR_SECRET",
      "oauth_token": "ACCESS_TOKEN_FROM_STEP3",
      "oauth_token_secret": "SECRET_FROM_STEP3"
    }
  }'
```
