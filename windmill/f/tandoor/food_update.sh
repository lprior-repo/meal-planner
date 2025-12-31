# shellcheck shell=bash
# Update a food in Tandoor
# Arguments: tandoor (resource), food_id (integer), name (string, optional), description (string, optional)

tandoor="$1"
food_id="$2"
name="$3"
description="$4"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson food_id "$food_id" \
	--arg name "$name" \
	--arg description "$description" \
	'{tandoor: $tandoor, food_id: $food_id} + (if $name != "" then {name: $name} else {} end) + (if $description != "" then {description: $description} else {} end)')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_food_update >./result.json
