---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-41
heading_path: ["Windmill Deployment Guide", "OAuth Configuration"]
chunk_type: code
tokens: 213
summary: "OAuth Configuration"
---

## OAuth Configuration

### FatSecret OAuth 1.0a Setup

FatSecret uses 3-legged OAuth 1.0a authentication.

#### 1. Register Application

1. Go to [FatSecret Platform](https://platform.fatsecret.com)
2. Create a new application
3. Note the Consumer Key and Consumer Secret

#### 2. Configure Callback URLs

**Development:**
```
http://localhost:6969/api/oauth/fatsecret/callback
```text

**Staging:**
```
https://staging.meal-planner.example.com/api/oauth/fatsecret/callback
```text

**Production:**
```
https://meal-planner.example.com/api/oauth/fatsecret/callback
```text

#### 3. OAuth Flow Implementation

```rust
// Windmill script: f/meal-planner/handlers/fatsecret/oauth_start
use oauth1_twitter_api::OAuth1;

pub fn main(user_id: String) -> Result<String, Error> {
    let consumer_key = wmill::get_variable("f/meal-planner/vars/fatsecret_key")?;
    let consumer_secret = wmill::get_variable("f/meal-planner/vars/fatsecret_secret")?;

    let oauth = OAuth1::new(consumer_key, consumer_secret);
    let request_token = oauth.get_request_token(CALLBACK_URL)?;

    // Store request token temporarily
    store_request_token(user_id, &request_token)?;

    // Return authorization URL
    Ok(oauth.get_authorize_url(&request_token))
}
```text

#### 4. Token Storage Schema

```sql
CREATE TABLE oauth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    provider VARCHAR(50) NOT NULL,
    access_token_encrypted BYTEA NOT NULL,
    access_token_secret_encrypted BYTEA,
    refresh_token_encrypted BYTEA,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_oauth_tokens_user_provider ON oauth_tokens(user_id, provider);
```text

#### 5. Encryption Key Generation

```bash
