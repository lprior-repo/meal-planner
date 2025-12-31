# shellcheck shell=bash
# Get FatSecret user profile
# Arguments: fatsecret (resource)

fatsecret="$1"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	'{fatsecret: $fatsecret}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_get_profile >./result.json
