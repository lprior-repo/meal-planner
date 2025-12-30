---
id: ops/fatsecret/guides-error-codes
title: "FatSecret Platform API - Error Codes"
category: ops
tags: ["api", "fatsecret", "operations", "advanced"]
---

# FatSecret Platform API - Error Codes

> **Context**: This guide documents error codes returned by the FatSecret Platform API.

This guide documents error codes returned by the FatSecret Platform API.

## Error Response Format

```json
{
  "error": {
    "code": 101,
    "message": "Missing required parameter: search_expression"
  }
}
```text

## OAuth 1.0 Errors

| Code | Description |
|------|-------------|
| 2 | Missing required OAuth parameter |
| 3 | Unsupported OAuth parameter |
| 4 | Invalid signature method - must be HMAC-SHA1 |
| 5 | Invalid consumer key |
| 6 | Invalid/expired timestamp |
| 7 | Invalid/used nonce |
| 8 | Invalid signature |
| 9 | Invalid/expired access token |

## OAuth 2.0 Errors

| Code | Description |
|------|-------------|
| 13 | Invalid access token |
| 14 | Access token has expired |

## General Errors

| Code | Description |
|------|-------------|
| 1 | General error - see message for details |
| 10 | Invalid API method |
| 11 | Method requires secure connection (HTTPS) |
| 12 | Method not accessible with current authentication |
| 20 | User does not have permission for this action |
| 21 | User account is suspended |
| 22 | Rate limit exceeded |
| 23 | API access disabled for this account |
| 24 | Feature not available for current plan |

## Parameter Errors

| Code | Description |
|------|-------------|
| 101 | Missing required parameter |
| 102 | Invalid parameter type |
| 103 | Invalid parameter value |
| 104 | Parameter value out of range |
| 105 | Invalid date format |
| 106 | Invalid food_id |
| 107 | Invalid serving_id |
| 108 | Invalid recipe_id |
| 109 | Invalid food_entry_id |

## Application Errors

| Code | Description |
|------|-------------|
| 201 | Food not found |
| 202 | Recipe not found |
| 203 | Serving not found |
| 204 | Food entry not found |
| 205 | Exercise entry not found |
| 206 | Weight entry not found |
| 207 | User profile not found |
| 208 | Meal not found |
| 209 | Brand not found |
| 210 | Duplicate entry |
| 211 | Maximum limit reached |

## Handling Errors

### HTTP Status Codes

- **200** - Success
- **400** - Bad Request (parameter errors)
- **401** - Unauthorized (authentication errors)
- **403** - Forbidden (permission errors)
- **404** - Not Found (resource errors)
- **429** - Too Many Requests (rate limiting)
- **500** - Internal Server Error

### Example Error Handling (Python)

```python
import requests

def api_request(url, params, headers):
    response = requests.get(url, params=params, headers=headers)
    
    if response.status_code == 429:
        # Rate limited - wait and retry
        retry_after = int(response.headers.get('Retry-After', 60))
        time.sleep(retry_after)
        return api_request(url, params, headers)
    
    data = response.json()
    
    if 'error' in data:
        error = data['error']
        code = error.get('code')
        message = error.get('message')
        
        if code in [13, 14]:
            # Token expired - refresh and retry
            refresh_token()
            return api_request(url, params, headers)
        elif code in [2, 3, 4, 5, 6, 7, 8]:
            # OAuth 1.0 signature error
            raise AuthenticationError(f"OAuth error {code}: {message}")
        elif code in [101, 102, 103, 104, 105]:
            # Parameter error
            raise ValueError(f"Parameter error {code}: {message}")
        elif code in [201, 202, 203, 204, 205, 206]:
            # Resource not found
            raise NotFoundError(f"Not found {code}: {message}")
        else:
            raise APIError(f"API error {code}: {message}")
    
    return data
```text

### Example Error Handling (Rust)

```rust
use serde::Deserialize;
use thiserror::Error;

#[derive(Debug, Deserialize)]
pub struct FatSecretError {
    pub code: u32,
    pub message: String,
}

#[derive(Debug, Error)]
pub enum ApiError {
    #[error("Authentication error ({0}): {1}")]
    Auth(u32, String),
    
    #[error("Parameter error ({0}): {1}")]
    Parameter(u32, String),
    
    #[error("Not found ({0}): {1}")]
    NotFound(u32, String),
    
    #[error("Rate limited")]
    RateLimited,
    
    #[error("API error ({0}): {1}")]
    Other(u32, String),
}

impl From<FatSecretError> for ApiError {
    fn from(e: FatSecretError) -> Self {
        match e.code {
            2..=9 | 13 | 14 => ApiError::Auth(e.code, e.message),
            101..=109 => ApiError::Parameter(e.code, e.message),
            201..=211 => ApiError::NotFound(e.code, e.message),
            22 => ApiError::RateLimited,
            _ => ApiError::Other(e.code, e.message),
        }
    }
}
```

## Rate Limiting

- Rate limits vary by subscription plan
- When rate limited, wait for the duration specified in the `Retry-After` header
- Implement exponential backoff for repeated failures
- Cache responses where appropriate to reduce API calls

## Best Practices

1. Always check for errors in API responses
2. Implement proper retry logic for transient errors
3. Log error codes and messages for debugging
4. Use appropriate HTTP status codes in your application
5. Provide meaningful error messages to users


## See Also

- [Documentation Index](./COMPASS.md)
