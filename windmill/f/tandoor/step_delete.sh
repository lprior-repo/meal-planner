# shellcheck shell=bash
# Delete a recipe step from Tandoor
# Arguments: tandoor (resource), id (integer)

tandoor="$1"
id="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	'{tandoor: $tandoor, id: $id}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_step_delete >./result.json
