# shellcheck shell=bash
# Autocomplete FatSecret food names
# Arguments: fatsecret (resource), expression (string), max_results (int)

fatsecret="$1"
expression="$2"
max_results="${3:-10}"

# Build JSON input for binary
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg expression "$expression" \
	--argjson max_results "$max_results" \
	'{fatsecret: $fatsecret, expression: $expression, max_results: $max_results}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/fatsecret_foods_autocomplete >./result.json
