---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-7
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Complete Flow Example (Python)"]
chunk_type: prose
tokens: 197
summary: "Complete Flow Example (Python)"
---

## Complete Flow Example (Python)

```python
import hmac
import hashlib
import base64
import time
import uuid
import urllib.parse
import requests

class FatSecretOAuth:
    def __init__(self, consumer_key, consumer_secret):
        self.consumer_key = consumer_key
        self.consumer_secret = consumer_secret
    
    def _sign_request(self, method, url, params, token_secret=''):
        oauth_params = {
            'oauth_consumer_key': self.consumer_key,
            'oauth_signature_method': 'HMAC-SHA1',
            'oauth_timestamp': str(int(time.time())),
            'oauth_nonce': uuid.uuid4().hex,
            'oauth_version': '1.0'
        }
        all_params = {**params, **oauth_params}
        
        sorted_params = sorted(all_params.items())
        param_string = urllib.parse.urlencode(sorted_params)
        
        base_string = '&'.join([
            method,
            urllib.parse.quote(url, safe=''),
            urllib.parse.quote(param_string, safe='')
        ])
        
        signing_key = f"{self.consumer_secret}&{token_secret}"
        
        signature = base64.b64encode(
            hmac.new(
                signing_key.encode(),
                base_string.encode(),
                hashlib.sha1
            ).digest()
        ).decode()
        
        all_params['oauth_signature'] = signature
        return all_params
    
    def get_request_token(self, callback_url='oob'):
        url = 'https://authentication.fatsecret.com/oauth/request_token'
        params = self._sign_request('GET', url, {'oauth_callback': callback_url})
        
        response = requests.get(url, params=params)
        data = urllib.parse.parse_qs(response.text)
        
        return {
            'oauth_token': data['oauth_token'][0],
            'oauth_token_secret': data['oauth_token_secret'][0]
        }
    
    def get_authorization_url(self, request_token):
        return f"https://authentication.fatsecret.com/oauth/authorize?oauth_token={request_token}"
    
    def get_access_token(self, request_token, request_token_secret, verifier):
        url = 'https://authentication.fatsecret.com/oauth/access_token'
        params = self._sign_request(
            'GET', url,
            {'oauth_token': request_token, 'oauth_verifier': verifier},
            request_token_secret
        )
        
        response = requests.get(url, params=params)
        data = urllib.parse.parse_qs(response.text)
        
        return {
            'oauth_token': data['oauth_token'][0],
            'oauth_token_secret': data['oauth_token_secret'][0]
        }
