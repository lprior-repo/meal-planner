---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-6
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Example Implementation"]
chunk_type: prose
tokens: 158
summary: "Example Implementation"
---

## Example Implementation

### Python

```python
import hmac
import hashlib
import base64
import time
import uuid
import urllib.parse
import requests

def oauth1_request(consumer_key, consumer_secret, method, params):
    base_url = "https://platform.fatsecret.com/rest/server.api"
    
    # OAuth parameters
    oauth_params = {
        'oauth_consumer_key': consumer_key,
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_timestamp': str(int(time.time())),
        'oauth_nonce': str(uuid.uuid4().hex),
        'oauth_version': '1.0'
    }
    
    # Combine all parameters
    all_params = {**params, **oauth_params, 'method': method}
    
    # Sort and encode parameters
    sorted_params = sorted(all_params.items())
    param_string = urllib.parse.urlencode(sorted_params)
    
    # Create signature base string
    base_string = '&'.join([
        'POST',
        urllib.parse.quote(base_url, safe=''),
        urllib.parse.quote(param_string, safe='')
    ])
    
    # Create signing key (no token secret for signed requests)
    signing_key = f"{consumer_secret}&"
    
    # Calculate signature
    signature = base64.b64encode(
        hmac.new(
            signing_key.encode('utf-8'),
            base_string.encode('utf-8'),
            hashlib.sha1
        ).digest()
    ).decode('utf-8')
    
    # Add signature to parameters
    all_params['oauth_signature'] = signature
    
    # Make request
    response = requests.post(base_url, data=all_params)
    return response.json()
