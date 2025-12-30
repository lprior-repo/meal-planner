---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-4
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Step 2: User Authorization"]
chunk_type: code
tokens: 124
summary: "Step 2: User Authorization"
---

## Step 2: User Authorization

Redirect the user to FatSecret to authorize your application.

**Authorization URL:** `https://authentication.fatsecret.com/oauth/authorize`

**Parameters:**
- `oauth_token` - The request token from Step 1

**Example Redirect:**

```yaml
https://authentication.fatsecret.com/oauth/authorize?oauth_token=REQUEST_TOKEN
```text

The user will:
1. Log in to FatSecret (if not already logged in)
2. Review the permissions your application is requesting
3. Approve or deny access

**After Authorization:**

- If `oauth_callback` was provided: User is redirected to your callback URL with `oauth_token` and `oauth_verifier` parameters
- If `oauth_callback=oob`: User is shown a verification code to enter in your application

**Callback Example:**

```yaml
https://yourapp.com/callback?oauth_token=REQUEST_TOKEN&oauth_verifier=VERIFIER_CODE
```text
