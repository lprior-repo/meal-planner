# shellcheck shell=bash
# Test Tandoor API connection
# Arguments: tandoor (resource)

tandoor="$1"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	'{tandoor: $tandoor}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_test_connection >./result.json
