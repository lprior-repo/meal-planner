# shellcheck shell=bash
# Create a new unit in Tandoor
# Arguments: tandoor (resource), name (string), plural_name (string, optional)

tandoor="$1"
name="$2"
plural_name="$3"

# Build JSON input for binary
if [ -n "$plural_name" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		--arg plural_name "$plural_name" \
		'{tandoor: $tandoor, name: $name, plural_name: $plural_name}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--arg name "$name" \
		'{tandoor: $tandoor, name: $name}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_unit_create >./result.json
