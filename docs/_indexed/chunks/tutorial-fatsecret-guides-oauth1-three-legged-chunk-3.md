---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-3
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Step 1: Obtaining a Request Token"]
chunk_type: code
tokens: 81
summary: "Step 1: Obtaining a Request Token"
---

## Step 1: Obtaining a Request Token

Request a temporary token from FatSecret.

**Endpoint:** `GET https://authentication.fatsecret.com/oauth/request_token`

**Required OAuth Parameters:**
- `oauth_consumer_key`
- `oauth_signature_method` (HMAC-SHA1)
- `oauth_timestamp`
- `oauth_nonce`
- `oauth_version` (1.0)
- `oauth_callback` (your callback URL or `oob` for out-of-band)
- `oauth_signature`

**Example Request:**

```bash
curl "https://authentication.fatsecret.com/oauth/request_token?oauth_consumer_key=YOUR_KEY&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=abc123&oauth_version=1.0&oauth_callback=https%3A%2F%2Fyourapp.com%2Fcallback&oauth_signature=SIGNATURE"
```text

**Response:**

```
oauth_token=REQUEST_TOKEN&oauth_token_secret=REQUEST_TOKEN_SECRET
```text

**Store these values** - you'll need them for the next steps.
