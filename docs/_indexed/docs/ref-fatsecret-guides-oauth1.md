---
id: ref/fatsecret/guides-oauth1
title: "FatSecret Platform API - OAuth 1.0 Guide"
category: ref
tags: ["api", "fatsecret", "oauth", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>FatSecret Platform API - OAuth 1.0 Guide</title>
  <description>OAuth 1.0 authentication requires signing each request with your credentials.</description>
  <created_at>2026-01-02T19:55:26.871982</created_at>
  <updated_at>2026-01-02T19:55:26.871982</updated_at>
  <language>en</language>
  <sections count="17">
    <section name="Required Parameters" level="2"/>
    <section name="Creating the Signature Base String" level="2"/>
    <section name="1. HTTP Method" level="3"/>
    <section name="2. Base URL" level="3"/>
    <section name="3. Parameter String" level="3"/>
    <section name="Combining Components" level="3"/>
    <section name="Calculating the Signature" level="2"/>
    <section name="1. Create the Signing Key" level="3"/>
    <section name="2. Calculate HMAC-SHA1" level="3"/>
    <section name="3. URL-Encode the Result" level="3"/>
  </sections>
  <features>
    <feature>1_create_the_signing_key</feature>
    <feature>1_http_method</feature>
    <feature>2_base_url</feature>
    <feature>2_calculate_hmac-sha1</feature>
    <feature>3_parameter_string</feature>
    <feature>3_url-encode_the_result</feature>
    <feature>as_authorization_header</feature>
    <feature>as_query_parameters_get</feature>
    <feature>calculating_the_signature</feature>
    <feature>combining_components</feature>
    <feature>common_issues</feature>
    <feature>creating_the_signature_base_string</feature>
    <feature>example_implementation</feature>
    <feature>python</feature>
    <feature>python_calculate_signature</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>api,fatsecret,oauth,reference</tags>
</doc_metadata>
-->

# FatSecret Platform API - OAuth 1.0 Guide

> **Context**: OAuth 1.0 authentication requires signing each request with your credentials.

OAuth 1.0 authentication requires signing each request with your credentials.

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

## Creating the Signature Base String

The signature base string is constructed from three components:

### 1. HTTP Method

Uppercase HTTP method (typically `GET` or `POST`).

### 2. Base URL

The request URL without query parameters, URL-encoded:

```text
https%3A%2F%2Fplatform.fatsecret.com%2Frest%2Fserver.api
```text

### 3. Parameter String

All parameters (OAuth + request parameters) sorted alphabetically, URL-encoded:

```bash
format=json&method=foods.search&oauth_consumer_key=YOUR_KEY&oauth_nonce=abc123&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_version=1.0&search_expression=chicken
```

### Combining Components

Join the three components with `&`:

```text
GET&https%3A%2F%2Fplatform.fatsecret.com%2Frest%2Fserver.api&format%3Djson%26method%3Dfoods.search%26oauth_consumer_key%3DYOUR_KEY%26oauth_nonce%3Dabc123%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1234567890%26oauth_version%3D1.0%26search_expression%3Dchicken
```text

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

## Usage
result = oauth1_request(
    'YOUR_CONSUMER_KEY',
    'YOUR_CONSUMER_SECRET',
    'foods.search',
    {'search_expression': 'chicken', 'format': 'json'}
)
print(result)
```

## Timestamp and Nonce

- **Timestamp:** Must be within 5 minutes of server time
- **Nonce:** Must be unique for each timestamp; prevents replay attacks

## Common Issues

1. **Signature mismatch** - Double-check URL encoding and parameter sorting
2. **Timestamp expired** - Ensure system clock is synchronized
3. **Nonce reuse** - Generate a new nonce for each request
4. **Encoding issues** - Use RFC 3986 percent-encoding


## See Also

- [Documentation Index](./COMPASS.md)
