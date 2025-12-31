# shellcheck shell=bash
# Create a new supermarket in Tandoor
# Arguments: tandoor (resource), name (string), description (string, optional)

tandoor="$1"
name="$2"
description="$3"

# Build JSON input for binary
if [ -n "$description" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		--arg description "$description" \
		'{tandoor: $tandoor, name: $name, description: $description}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		'{tandoor: $tandoor, name: $name}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_supermarket_create >./result.json
