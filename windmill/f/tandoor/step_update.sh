# shellcheck shell=bash
# Update a recipe step in Tandoor
# Arguments: tandoor (resource), id (integer), instruction (string)

tandoor="$1"
id="$2"
instruction="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	--arg instruction "$instruction" \
	'{tandoor: $tandoor, id: $id, instruction: $instruction}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_step_update >./result.json
