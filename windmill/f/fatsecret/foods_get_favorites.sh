# shellcheck shell=bash
# Get FatSecret favorite foods
# Arguments: fatsecret (resource), access_token, access_secret

fatsecret="$1"
access_token="$2"
access_secret="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	'{
		fatsecret: $fatsecret,
		access_token: $access_token,
		access_secret: $access_secret
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/fatsecret_foods_get_favorites >./result.json
