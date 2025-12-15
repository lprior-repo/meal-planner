#!/usr/bin/env bash
set -euo pipefail

# Pull today's food data from FatSecret (12/15/2025)

# Load environment
export $(grep -E "^(OAUTH_ENCRYPTION_KEY|FATSECRET_CONSUMER_KEY|FATSECRET_CONSUMER_SECRET|DATABASE_URL)" /home/lewis/src/meal-planner/.env | xargs)

# Get OAuth token from database
OAUTH_DATA=$(psql "${DATABASE_URL}" -t -c "
SELECT oauth_token, oauth_token_secret
FROM fatsecret_oauth_token
WHERE id = 1;
" 2>/dev/null)

if [ -z "$OAUTH_DATA" ]; then
  echo "❌ No OAuth token found in database"
  exit 1
fi

OAUTH_TOKEN=$(echo "$OAUTH_DATA" | cut -d'|' -f1 | xargs)
OAUTH_TOKEN_SECRET=$(echo "$OAUTH_DATA" | cut -d'|' -f2 | xargs)

echo "✅ OAuth token loaded from database"
echo "🔐 Token (first 20 chars): ${OAUTH_TOKEN:0:20}..."

# FatSecret API call parameters
METHOD="POST"
URL="https://platform.fatsecret.com/rest/server.api"
DATE_INT="20558"  # 2025-12-15

# OAuth 1.0a signing
OAUTH_NONCE=$(openssl rand -hex 16)
OAUTH_TIMESTAMP=$(date +%s)
CONSUMER_KEY="$FATSECRET_CONSUMER_KEY"
CONSUMER_SECRET="$FATSECRET_CONSUMER_SECRET"

# Build parameter string (alphabetical order)
PARAMS="date_int=${DATE_INT}&method=food_entries.get&oauth_consumer_key=${CONSUMER_KEY}&oauth_nonce=${OAUTH_NONCE}&oauth_signature_method=HMAC-SHA1&oauth_timestamp=${OAUTH_TIMESTAMP}&oauth_token=${OAUTH_TOKEN}&oauth_version=1.0"

# Create signature base string
SIGNATURE_BASE_STRING="${METHOD}&$(python3 -c "import urllib.parse; print(urllib.parse.quote('${URL}', safe=''))")&$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PARAMS}', safe=''))")"

# Create signing key
SIGNING_KEY="${CONSUMER_SECRET}&${OAUTH_TOKEN_SECRET}"

# Create HMAC-SHA1 signature
OAUTH_SIGNATURE=$(echo -n "${SIGNATURE_BASE_STRING}" | openssl dgst -sha1 -hmac "${SIGNING_KEY}" -binary | base64)

echo "📡 Calling FatSecret API..."
echo "   Date: 2025-12-15 (date_int: ${DATE_INT})"

# Make the API request
RESPONSE=$(curl -s -X POST "${URL}" \
  -d "method=food_entries.get&date_int=${DATE_INT}" \
  -H "Authorization: OAuth oauth_consumer_key=\"${CONSUMER_KEY}\",oauth_token=\"${OAUTH_TOKEN}\",oauth_signature_method=\"HMAC-SHA1\",oauth_signature=\"${OAUTH_SIGNATURE}\",oauth_timestamp=\"${OAUTH_TIMESTAMP}\",oauth_nonce=\"${OAUTH_NONCE}\",oauth_version=\"1.0\"" \
  -H "Content-Type: application/x-www-form-urlencoded")

# Pretty print response
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📊 FOOD ENTRIES FOR 2025-12-15"
echo "═══════════════════════════════════════════════════════════════"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
echo ""
echo "✅ Done!"
