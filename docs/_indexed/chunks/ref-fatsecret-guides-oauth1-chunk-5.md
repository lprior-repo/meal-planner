---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-5
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Sending the Request"]
chunk_type: code
tokens: 59
summary: "Sending the Request"
---

## Sending the Request

Include all OAuth parameters plus the signature in the request:

### As Query Parameters (GET)

```bash
curl "https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=chicken&format=json&oauth_consumer_key=YOUR_KEY&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=abc123&oauth_version=1.0&oauth_signature=CALCULATED_SIGNATURE"
```text

### As Authorization Header

```bash
curl -X POST "https://platform.fatsecret.com/rest/server.api" \
  -H "Authorization: OAuth oauth_consumer_key=\"YOUR_KEY\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1234567890\", oauth_nonce=\"abc123\", oauth_version=\"1.0\", oauth_signature=\"CALCULATED_SIGNATURE\"" \
  -d "method=foods.search&search_expression=chicken&format=json"
```text
