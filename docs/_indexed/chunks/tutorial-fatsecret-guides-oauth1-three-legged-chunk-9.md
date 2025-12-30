---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-9
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Step 1: Get request token"]
chunk_type: prose
tokens: 15
summary: "Step 1: Get request token"
---

## Step 1: Get request token
request = oauth.get_request_token('https://yourapp.com/callback')
print(f"Request Token: {request['oauth_token']}")
