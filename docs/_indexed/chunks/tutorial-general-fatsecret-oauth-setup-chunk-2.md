---
doc_id: tutorial/general/fatsecret-oauth-setup
chunk_id: tutorial/general/fatsecret-oauth-setup#chunk-2
heading_path: ["FatSecret OAuth Setup (One-Time)", "Step 1: Get Auth URL"]
chunk_type: prose
tokens: 35
summary: "Step 1: Get Auth URL"
---

## Step 1: Get Auth URL

```bash
wmill script run f/fatsecret/oauth_start \
  -d '{"fatsecret": "$res:u/admin/fatsecret_api", "callback_url": "oob"}' \
  2>&1 | tail -5
```

Save: `oauth_token`, `oauth_token_secret`, `auth_url`
