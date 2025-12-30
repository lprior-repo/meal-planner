# shellcheck shell=bash
# Complete FatSecret OAuth flow - exchanges verifier for access token
# Arguments: fatsecret (resource), oauth_token (string), oauth_verifier (string)

fatsecret="$1"
oauth_token="$2"
oauth_verifier="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg oauth_token "$oauth_token" \
	--arg oauth_verifier "$oauth_verifier" \
	'{fatsecret: $fatsecret, oauth_token: $oauth_token, oauth_verifier: $oauth_verifier}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_oauth_complete >./result.json
