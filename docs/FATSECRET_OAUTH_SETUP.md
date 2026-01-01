# FatSecret OAuth Setup (One-Time)

Complete the 3-legged OAuth flow once. After this, use `$res:u/admin/fatsecret_oauth` in all scripts.

**Prerequisites**: FatSecret developer account with Consumer Key and Secret already stored in `u/admin/fatsecret_api`.

## Step 1: Get Auth URL

```bash
wmill script run f/fatsecret/oauth_start \
  -d '{"fatsecret": "$res:u/admin/fatsecret_api", "callback_url": "oob"}' \
  2>&1 | tail -5
```

Save: `oauth_token`, `oauth_token_secret`, `auth_url`

## Step 2: Authorize in Browser

1. Visit the `auth_url`
2. Log in with FatSecret
3. Click "Authorize"
4. Copy the verifier code (6-8 digits)

## Step 3: Exchange Verifier

```bash
wmill script run f/fatsecret/oauth_complete -d '{
  "fatsecret": "$res:u/admin/fatsecret_api",
  "oauth_token": "TOKEN_FROM_STEP1",
  "oauth_token_secret": "SECRET_FROM_STEP1",
  "oauth_verifier": "CODE_FROM_STEP2"
}' 2>&1 | tail -5
```

Save: `oauth_token`, `oauth_token_secret` (these are permanent access tokens)

## Step 4: Store in Windmill

```bash
TOKEN=$(grep -oP '"token":"\K[^"]+' ~/.config/windmill/remotes.ndjson)

curl -s -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "u/admin/fatsecret_oauth",
    "resource_type": "fatsecret",
    "value": {
      "consumer_key": "YOUR_KEY",
      "consumer_secret": "YOUR_SECRET",
      "oauth_token": "ACCESS_TOKEN_FROM_STEP3",
      "oauth_token_secret": "SECRET_FROM_STEP3"
    }
  }'
```

## Step 5: Verify

```bash
wmill script run f/fatsecret/get_profile \
  -d '{"fatsecret": "$res:u/admin/fatsecret_oauth", "oauth_token": "...", "oauth_token_secret": "..."}' \
  2>&1 | tail -10
```

Should show your FatSecret profile data.

## Done

Tokens are encrypted in Windmill database. All scripts use `$res:u/admin/fatsecret_oauth`.

See: [AGENTS.md](../AGENTS.md) for where tokens are stored
