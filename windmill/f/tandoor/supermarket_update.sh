# shellcheck shell=bash
# Update a supermarket in Tandoor
# Arguments: tandoor (resource), id (integer), name (string), description (string, optional)

tandoor="$1"
id="$2"
name="$3"
description="$4"

# Build JSON input for binary
if [ -n "$description" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson id "$id" \
		--arg name "$name" \
		--arg description "$description" \
		'{tandoor: $tandoor, id: $id, name: $name, description: $description}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson id "$id" \
		--arg name "$name" \
		'{tandoor: $tandoor, id: $id, name: $name}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_supermarket_update >./result.json
