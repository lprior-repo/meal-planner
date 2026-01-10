# shellcheck shell=bash
# Get FatSecret OAuth access token from secure storage
# Arguments: check_only (optional, defaults to false)

check_only="${1:-false}"

# Build JSON input for binary
input=$(jq -n \
	--argjson check_only "$check_only" \
	'{check_only: $check_only}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_get_token >./result.json
