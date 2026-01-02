# shellcheck shell=bash
# Get FatSecret user profile
# Arguments: fatsecret (resource), oauth_token (string), oauth_token_secret (string)

fatsecret="$1"
oauth_token="$2"
oauth_token_secret="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg oauth_token "$oauth_token" \
	--arg oauth_token_secret "$oauth_token_secret" \
	'{fatsecret: $fatsecret, oauth_token: $oauth_token, oauth_token_secret: $oauth_token_secret}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_get_profile >./result.json
