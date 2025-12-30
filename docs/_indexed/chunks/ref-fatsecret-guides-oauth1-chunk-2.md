---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-2
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Required Parameters"]
chunk_type: prose
tokens: 84
summary: "Required Parameters"
---

## Required Parameters

Every OAuth 1.0 request must include these parameters:

| Parameter | Description |
|-----------|-------------|
| `oauth_consumer_key` | Your API Consumer Key |
| `oauth_signature_method` | Must be `HMAC-SHA1` |
| `oauth_timestamp` | Unix timestamp (seconds since epoch) |
| `oauth_nonce` | Unique random string for this request |
| `oauth_version` | Must be `1.0` |
| `oauth_signature` | Calculated signature value |
