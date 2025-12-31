# shellcheck shell=bash
# Create a new food in Tandoor
# Arguments: tandoor (resource), name (string), description (string, optional)

tandoor="$1"
name="$2"
description="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg name "$name" \
	--arg description "$description" \
	'{tandoor: $tandoor, name: $name} + (if $description != "" then {description: $description} else {} end)')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_food_create >./result.json
