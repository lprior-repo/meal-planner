# shellcheck shell=bash
# List recipes in flat format (without pagination wrapper)
# Arguments: tandoor (resource), limit (integer, optional), offset (integer, optional)

tandoor="$1"
limit="${2:-}"
offset="${3:-}"

# Build JSON input for binary with optional fields
if [ -n "$limit" ] && [ -n "$offset" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson limit "$limit" \
		--argjson offset "$offset" \
		'{tandoor: $tandoor, limit: $limit, offset: $offset}')
elif [ -n "$limit" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson limit "$limit" \
		'{tandoor: $tandoor, limit: $limit}')
elif [ -n "$offset" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson offset "$offset" \
		'{tandoor: $tandoor, offset: $offset}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		'{tandoor: $tandoor}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_recipe_list_flat >./result.json
