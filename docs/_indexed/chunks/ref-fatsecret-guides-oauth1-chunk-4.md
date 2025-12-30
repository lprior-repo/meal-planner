---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-4
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Calculating the Signature"]
chunk_type: code
tokens: 87
summary: "Calculating the Signature"
---

## Calculating the Signature

### 1. Create the Signing Key

For signed requests (no user token):
```json
{consumer_secret}&
```

For delegated requests (with user token):
```json
{consumer_secret}&{token_secret}
```python

### 2. Calculate HMAC-SHA1

```python
import hmac
import hashlib
import base64

def calculate_signature(base_string, signing_key):
    hashed = hmac.new(
        signing_key.encode('utf-8'),
        base_string.encode('utf-8'),
        hashlib.sha1
    )
    return base64.b64encode(hashed.digest()).decode('utf-8')
```text

### 3. URL-Encode the Result

The signature must be URL-encoded before including in the request.
