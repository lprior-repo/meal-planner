# shellcheck shell=bash
# Batch update foods in Tandoor
# Arguments: tandoor (resource), updates (array of {id, name?, description?})

tandoor="$1"
updates="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson updates "$updates" \
	'{tandoor: $tandoor, updates: $updates}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_food_batch_update >./result.json
