---
doc_id: ops/fatsecret/guides-error-codes
chunk_id: ops/fatsecret/guides-error-codes#chunk-8
heading_path: ["FatSecret Platform API - Error Codes", "Handling Errors"]
chunk_type: code
tokens: 366
summary: "Handling Errors"
---

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
