# shellcheck shell=bash
# Get a specific keyword from Tandoor
# Arguments: tandoor (resource), keyword_id (integer)

tandoor="$1"
keyword_id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson keyword_id "$keyword_id" \
	'{tandoor: $tandoor, keyword_id: $keyword_id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_keyword_get >./result.json
