# shellcheck shell=bash
# Create a new keyword in Tandoor
# Arguments: tandoor (resource), name

tandoor="$1"
name="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg name "$name" \
	'{tandoor: $tandoor, name: $name}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_keyword_create >./result.json
