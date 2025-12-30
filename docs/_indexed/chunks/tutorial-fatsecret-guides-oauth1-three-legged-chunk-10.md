---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-10
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Step 2: Redirect user to authorization URL"]
chunk_type: prose
tokens: 18
summary: "Step 2: Redirect user to authorization URL"
---

## Step 2: Redirect user to authorization URL
auth_url = oauth.get_authorization_url(request['oauth_token'])
print(f"Authorize at: {auth_url}")
