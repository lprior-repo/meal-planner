---
id: tutorial/fatsecret/guides-oauth1-three-legged
title: "FatSecret Platform API - 3-Legged OAuth"
category: tutorial
tags: ["fatsecret", "beginner", "api", "oauth", "tutorial"]
---

# FatSecret Platform API - 3-Legged OAuth

> **Context**: 3-legged OAuth allows your application to access user-specific data on their behalf. This is required for food diaries, weight tracking, and exercise 

3-legged OAuth allows your application to access user-specific data on their behalf. This is required for food diaries, weight tracking, and exercise logs.

**Note:** 3-legged OAuth is only available with OAuth 1.0.

## Overview

The 3-legged OAuth flow involves three parties:
1. **Your Application** (Consumer)
2. **FatSecret** (Service Provider)
3. **The User** (Resource Owner)

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

```bash
oauth_token=REQUEST_TOKEN&oauth_token_secret=REQUEST_TOKEN_SECRET
```text

**Store these values** - you'll need them for the next steps.

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

## Usage
oauth = FatSecretOAuth('YOUR_CONSUMER_KEY', 'YOUR_CONSUMER_SECRET')

## Step 1: Get request token
request = oauth.get_request_token('https://yourapp.com/callback')
print(f"Request Token: {request['oauth_token']}")

## Step 2: Redirect user to authorization URL
auth_url = oauth.get_authorization_url(request['oauth_token'])
print(f"Authorize at: {auth_url}")

## Step 3: After user authorizes, exchange for access token
## verifier = input("Enter verifier code: ")
## access = oauth.get_access_token(
## request['oauth_token'],
## request['oauth_token_secret'],
## verifier
## )
## print(f"Access Token: {access['oauth_token']}")
```

## Token Lifetime

- **Request tokens** expire after a short time (typically 15 minutes)
- **Access tokens** do not expire but can be revoked by the user

## Security Considerations

1. Store access tokens securely (encrypted at rest)
2. Use HTTPS for all OAuth communications
3. Validate the `oauth_token` in callbacks matches what you sent
4. Implement CSRF protection for callback endpoints


## See Also

- [Documentation Index](./COMPASS.md)
