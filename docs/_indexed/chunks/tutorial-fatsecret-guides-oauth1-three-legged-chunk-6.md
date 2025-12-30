---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-6
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Using the Access Token"]
chunk_type: code
tokens: 55
summary: "Using the Access Token"
---

## Using the Access Token

Include the access token in subsequent API requests to access user data.

**Additional OAuth Parameters:**
- `oauth_token` - The access token

**Signature Calculation:**

```bash
signing_key = {consumer_secret}&{access_token_secret}
```text

**Example - Getting User's Food Diary:**

```bash
curl "https://platform.fatsecret.com/rest/server.api?method=food_entries.get&date=0&oauth_consumer_key=YOUR_KEY&oauth_token=ACCESS_TOKEN&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=def456&oauth_version=1.0&oauth_signature=SIGNATURE"
```text
