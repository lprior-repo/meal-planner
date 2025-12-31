# shellcheck shell=bash
# Update an existing keyword in Tandoor
# Arguments: tandoor (resource), id, name

tandoor="$1"
id="$2"
name="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	--arg name "$name" \
	'{tandoor: $tandoor, id: $id, name: $name}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_keyword_update >./result.json
