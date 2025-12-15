# Debugging FatSecret OAuth Integration

Issue: GET /api/fatsecret/diary/day/20437 returns 0 calories despite user having food logged in FatSecret.

Related Beads: meal-planner-2b8

## Three-Step Debugging Process

### Step 1: Verify OAuth Token Validity in Database

#### Check if token is stored:
```sql
-- Connect to PostgreSQL
psql -U postgres -d meal_planner

-- Check if token exists
SELECT id, oauth_token, oauth_token_secret, connected_at, last_used_at 
FROM fatsecret_oauth_token 
WHERE id = 1;
```

**Expected result:**
- If empty result: Token was never stored (OAuth flow failed)
- If has data: Token is stored, proceed to Step 2

#### Check encryption configuration:
```sql
-- This is checked in code via: storage.encryption_configured()
-- It verifies the OAUTH_ENCRYPTION_KEY environment variable is set

echo $OAUTH_ENCRYPTION_KEY
-- Should output a 64-character hex string (256-bit key)
-- Example: a0b1c2d3e4f5a0b1c2d3e4f5a0b1c2d3e4f5a0b1c2d3e4f5a0b1c2d3e4f5
```

#### Run the token validity test:
```bash
cd gleam
gleam test -- fatsecret/oauth_token_validity_test
```

---

### Step 2: Check Logs from HTTP Request

#### Enable debug logging:
The diary client now logs:
- Request parameters (date_int)
- Raw API response (first 1000 chars)
- Parsed entry count and total calories
- Any parsing errors

#### View logs:
```bash
# Check application logs (depends on your logging setup)
tail -f logs/meal-planner.log

# Look for lines like:
# [INFO] FatSecret: Requesting food entries for date_int=20437
# [DEBUG] FatSecret API response: {"food_entries":{"food_entry":[...]}}
# [INFO] FatSecret: Parsed 2 entries, total calories=1500.0

# Or if it fails:
# [ERROR] FatSecret: Failed to parse food entries response for date_int=20437
```

#### Code location for logging:
- File: `gleam/src/meal_planner/fatsecret/diary/client.gleam`
- Function: `get_food_entries()`
- Lines with logging:
  - Request log
  - Raw response debug
  - Parse result log (success or error)

---

### Step 3: Test FatSecret API Directly with curl

#### Get the stored OAuth token from database:
```sql
SELECT oauth_token, oauth_token_secret 
FROM fatsecret_oauth_token 
WHERE id = 1;
```

Save the oauth_token and oauth_token_secret values.

#### Construct and test the API call:

FatSecret uses OAuth 1.0a signing. The request signature must be computed.

**Quick test - using your stored credentials:**

```bash
#!/bin/bash

# Configuration
OAUTH_TOKEN="your_oauth_token_here"
OAUTH_TOKEN_SECRET="your_oauth_token_secret_here"
CONSUMER_KEY="your_consumer_key_here"
CONSUMER_SECRET="your_consumer_secret_here"
DATE_INT="20437"

# API endpoint
METHOD="POST"
URL="https://platform.fatsecret.com/rest/server.api"

# Build OAuth parameters
OAUTH_NONCE=$(openssl rand -hex 8)
OAUTH_TIMESTAMP=$(date +%s)
OAUTH_SIGNATURE_METHOD="HMAC-SHA1"
OAUTH_VERSION="1.0"

# Parameters to sign (in alphabetical order)
PARAMS="date_int=$DATE_INT&method=food_entries.get&oauth_consumer_key=$CONSUMER_KEY&oauth_nonce=$OAUTH_NONCE&oauth_signature_method=$OAUTH_SIGNATURE_METHOD&oauth_timestamp=$OAUTH_TIMESTAMP&oauth_token=$OAUTH_TOKEN&oauth_version=$OAUTH_VERSION"

# Create signature base string
SIGNATURE_BASE_STRING="$METHOD&$(echo -n "$URL" | jq -sRr @uri)&$(echo -n "$PARAMS" | jq -sRr @uri)"

# Create signing key (consumer_secret&token_secret)
SIGNING_KEY="$CONSUMER_SECRET&$OAUTH_TOKEN_SECRET"

# Create HMAC-SHA1 signature
OAUTH_SIGNATURE=$(echo -n "$SIGNATURE_BASE_STRING" | openssl dgst -sha1 -hmac "$SIGNING_KEY" -binary | base64)

# Make the request
curl -X POST "$URL" \
  -d "method=food_entries.get&date_int=$DATE_INT" \
  -H "Authorization: OAuth oauth_consumer_key=\"$CONSUMER_KEY\",oauth_token=\"$OAUTH_TOKEN\",oauth_signature_method=\"$OAUTH_SIGNATURE_METHOD\",oauth_signature=\"$OAUTH_SIGNATURE\",oauth_timestamp=\"$OAUTH_TIMESTAMP\",oauth_nonce=\"$OAUTH_NONCE\",oauth_version=\"$OAUTH_VERSION\"" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -v
```

#### Expected responses:

**Success with entries:**
```json
{
  "food_entries": {
    "food_entry": [
      {
        "food_entry_id": "123456",
        "food_entry_name": "Lunch",
        "food_id": "4142",
        "calories": "500",
        "carbohydrate": "60",
        "protein": "30",
        "fat": "15",
        "meal": "lunch",
        "date_int": "20437"
      }
    ]
  }
}
```

**No entries for that date:**
```json
{
  "food_entries": {
    "food_entry": []
  }
}
```

**Authentication error (token expired/invalid):**
```json
{
  "error": {
    "code": 130,
    "message": "Invalid OAuth Request"
  }
}
```

**Token revoked:**
```json
{
  "error": {
    "code": 408,
    "message": "Invalid oauth request"
  }
}
```

---

## Diagnosis Guide

### Issue: "0 calories" in response

Possible causes:
1. **Token not stored** → User never completed OAuth flow
2. **Token expired/revoked** → Curl test will show OAuth error
3. **Wrong date_int** → Verify date conversion (2025-12-15 = 20558)
4. **User has no entries for that date** → API returns empty array legitimately
5. **API response format changed** → Check raw response in logs

### Debugging checklist:

- [ ] Database has token stored: `SELECT * FROM fatsecret_oauth_token WHERE id = 1;`
- [ ] Encryption key is set: `echo $OAUTH_ENCRYPTION_KEY`
- [ ] Token is valid (not expired): Test with curl
- [ ] Date_int is correct: Verify conversion
- [ ] No parsing errors in logs: Check application logs
- [ ] API returns entries: Raw response in debug logs

### Common fixes:

1. **Token missing:** Re-run OAuth flow
   - POST /api/fatsecret/profile/auth/{user_id}
   - Follow authorization link
   - Complete callback

2. **Token expired:** Request new access token
   - Implement token refresh in OAuth flow
   - Or force user to re-authenticate

3. **Wrong response format:** Update decoders
   - Check FatSecret API documentation
   - Verify response structure matches expectations

4. **Date issue:** Fix date_int conversion
   - Verify date_to_int() function
   - Check timezone handling

---

## Code References

**Logging implementation:**
- File: `gleam/src/meal_planner/fatsecret/diary/client.gleam`
- Function: `get_food_entries()` - Lines with logging statements

**Token storage:**
- File: `gleam/src/meal_planner/fatsecret/storage.gleam`
- Functions: `get_access_token()`, `store_access_token()`

**Encryption:**
- File: `gleam/src/meal_planner/fatsecret/crypto.gleam`
- Functions: `encrypt()`, `decrypt()`

**Service layer:**
- File: `gleam/src/meal_planner/fatsecret/diary/service.gleam`
- Function: `get_day_entries()` - Handles token loading and error mapping

**HTTP handlers:**
- File: `gleam/src/meal_planner/fatsecret/diary/handlers.gleam`
- Function: `get_day()` - HTTP endpoint handler

**Tests for token validity:**
- File: `gleam/test/fatsecret/oauth_token_validity_test.gleam`
- Tests for encryption, response parsing, date conversion

---

## Next Steps

1. Run the token validity tests: `gleam test`
2. Enable debug logging in production
3. Reproduce the "0 calories" issue
4. Check logs for raw API response
5. Compare actual response with expected format
6. Fix decoder or token handling as needed
