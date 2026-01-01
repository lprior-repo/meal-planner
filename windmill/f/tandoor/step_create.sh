# shellcheck shell=bash
# Create a new recipe step in Tandoor
# Arguments: tandoor (resource), instruction (string)

tandoor="$1"
instruction="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg instruction "$instruction" \
	'{tandoor: $tandoor, instruction: $instruction}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_step_create >./result.json
