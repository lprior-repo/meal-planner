# shellcheck shell=bash
# Update an existing unit in Tandoor
# Arguments: tandoor (resource), id (number), name (string, optional), plural_name (string, optional)

tandoor="$1"
id="$2"
name="${3:-null}"
plural_name="${4:-null}"

# Build JSON input for binary
# Use --arg for strings (to properly quote them) and --argjson for numbers/null
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	--arg name "$name" \
	--arg plural_name "$plural_name" \
	'{tandoor: $tandoor, id: $id} + (if $name == "null" then {} else {name: $name} end) + (if $plural_name == "null" then {} else {plural_name: $plural_name} end)')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_unit_update >./result.json
