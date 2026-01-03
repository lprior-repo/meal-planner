---
doc_id: tutorial/general/fatsecret-oauth-setup
chunk_id: tutorial/general/fatsecret-oauth-setup#chunk-4
heading_path: ["FatSecret OAuth Setup (One-Time)", "Step 3: Exchange Verifier"]
chunk_type: prose
tokens: 44
summary: "Step 3: Exchange Verifier"
---

## Step 3: Exchange Verifier

```bash
wmill script run f/fatsecret/oauth_complete -d '{
  "fatsecret": "$res:u/admin/fatsecret_api",
  "oauth_token": "TOKEN_FROM_STEP1",
  "oauth_token_secret": "SECRET_FROM_STEP1",
  "oauth_verifier": "CODE_FROM_STEP2"
}' 2>&1 | tail -5
```

Save: `oauth_token`, `oauth_token_secret` (these are permanent access tokens)
