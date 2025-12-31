# shellcheck shell=bash
# Get a specific user from Tandoor by ID
# Arguments: tandoor (resource), user_id (number)

tandoor="$1"
user_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson user_id "$user_id" \
	'{tandoor: $tandoor, user_id: $user_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_user_get >./result.json
