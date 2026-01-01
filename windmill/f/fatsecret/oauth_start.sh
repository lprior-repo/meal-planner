# shellcheck shell=bash
# Start FatSecret OAuth flow - calls binary with JSON input
# Arguments: fatsecret (resource), callback_url (string)

fatsecret="$1"
callback_url="${2:-oob}"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg callback_url "$callback_url" \
	'{fatsecret: $fatsecret, callback_url: $callback_url}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_oauth_start >./result.json
