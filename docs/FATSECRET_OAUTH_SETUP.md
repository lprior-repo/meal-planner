# FatSecret OAuth Setup

This guide covers the one-time OAuth setup process for FatSecret integration.

**Note:** This setup is only needed once. After completing this, use the credentials stored in Windmill.

## Prerequisites

- FatSecret developer account with Consumer Key and Secret
- Access to Windmill UI at http://localhost:8000/

## Step 1: Get Authorization URL

```bash
wmill script run f/fatsecret/oauth_start -d '{"fatsecret": "$res:u/admin/fatsecret_api", "callback_url": "oob"}' 2>&1 | tail -5
```

**Output:**
```json
{
  "success": true,
  "auth_url": "https://authentication.fatsecret.com/oauth/authorize?oauth_token=XXX",
  "oauth_token": "REQUEST_TOKEN_HERE",
  "oauth_token_secret": "REQUEST_TOKEN_SECRET_HERE"
}
```

**Save:** The three values above (auth_url, oauth_token, oauth_token_secret)

## Step 2: Authorize in Browser

1. Visit the `auth_url` in your browser
2. Log in with FatSecret account
3. Click "Authorize"
4. Copy the verifier code shown (6-8 digits)

## Step 3: Exchange Verifier for Access Token

```bash
wmill script run f/fatsecret/oauth_complete -d '{
  "fatsecret": "$res:u/admin/fatsecret_api",
  "oauth_token": "REQUEST_TOKEN_HERE",
  "oauth_token_secret": "REQUEST_TOKEN_SECRET_HERE",
  "oauth_verifier": "YOUR_VERIFIER_CODE"
}' 2>&1 | tail -10
```

**Output:**
```json
{
  "success": true,
  "oauth_token": "ACCESS_TOKEN_HERE",
  "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
}
```

**Save:** The two access tokens (these are permanent)

## Step 4: Store Tokens in Windmill

Create a Windmill resource with the access tokens:

```bash
TOKEN="hLg0fT2LyCggnu7ViGVFnmqejPF1uWsI"  # From ~/.config/windmill/remotes.ndjson

curl -s -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "u/admin/fatsecret_oauth",
    "resource_type": "fatsecret",
    "value": {
      "consumer_key": "YOUR_CONSUMER_KEY_HERE",
      "consumer_secret": "YOUR_CONSUMER_SECRET_HERE",
      "oauth_token": "ACCESS_TOKEN_HERE",
      "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
    }
  }'
```

## Step 5: Verify

Test that it's working:

```bash
wmill script run f/fatsecret/get_profile -d '{
  "fatsecret": "$res:u/admin/fatsecret_oauth",
  "oauth_token": "ACCESS_TOKEN_HERE",
  "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
}' 2>&1 | tail -15
```

Should show your FatSecret profile data.

## Done

Tokens are now stored in Windmill encrypted database. All scripts will use `$res:u/admin/fatsecret_oauth` to access them.
