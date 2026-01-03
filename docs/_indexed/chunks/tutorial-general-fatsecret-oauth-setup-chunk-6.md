---
doc_id: tutorial/general/fatsecret-oauth-setup
chunk_id: tutorial/general/fatsecret-oauth-setup#chunk-6
heading_path: ["FatSecret OAuth Setup (One-Time)", "Step 5: Verify"]
chunk_type: prose
tokens: 37
summary: "Step 5: Verify"
---

## Step 5: Verify

```bash
wmill script run f/fatsecret/get_profile \
  -d '{"fatsecret": "$res:u/admin/fatsecret_oauth", "oauth_token": "...", "oauth_token_secret": "..."}' \
  2>&1 | tail -10
```

Should show your FatSecret profile data.
