# shellcheck shell=bash
# Complete FatSecret OAuth flow - exchanges verifier for access token
# Arguments: fatsecret (resource), oauth_token (string), oauth_token_secret (string), oauth_verifier (string)

fatsecret="$1"
oauth_token="$2"
oauth_token_secret="$3"
oauth_verifier="$4"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg oauth_token "$oauth_token" \
	--arg oauth_token_secret "$oauth_token_secret" \
	--arg oauth_verifier "$oauth_verifier" \
	'{fatsecret: $fatsecret, oauth_token: $oauth_token, oauth_token_secret: $oauth_token_secret, oauth_verifier: $oauth_verifier}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_oauth_complete >./result.json
