---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-5
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Step 3: Exchanging for an Access Token"]
chunk_type: code
tokens: 124
summary: "Step 3: Exchanging for an Access Token"
---

## Step 3: Exchanging for an Access Token

Exchange the authorized request token for a permanent access token.

**Endpoint:** `GET https://authentication.fatsecret.com/oauth/access_token`

**Required OAuth Parameters:**
- `oauth_consumer_key`
- `oauth_token` (the authorized request token)
- `oauth_signature_method` (HMAC-SHA1)
- `oauth_timestamp`
- `oauth_nonce`
- `oauth_version` (1.0)
- `oauth_verifier` (from the callback or user input)
- `oauth_signature`

**Important:** The signature must be calculated using both your consumer secret AND the request token secret:

```bash
signing_key = {consumer_secret}&{request_token_secret}
```text

**Example Request:**

```bash
curl "https://authentication.fatsecret.com/oauth/access_token?oauth_consumer_key=YOUR_KEY&oauth_token=REQUEST_TOKEN&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=xyz789&oauth_version=1.0&oauth_verifier=VERIFIER_CODE&oauth_signature=SIGNATURE"
```text

**Response:**

```bash
oauth_token=ACCESS_TOKEN&oauth_token_secret=ACCESS_TOKEN_SECRET
```text

**Store these values securely** - they provide ongoing access to the user's data.
