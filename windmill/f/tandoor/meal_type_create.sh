# shellcheck shell=bash
# Create a new meal type in Tandoor
# Arguments: tandoor (resource), name (string), order (optional), time (optional), color (optional), default (optional)

tandoor="$1"
name="$2"
order="$3"
time="$4"
color="$5"
default="$6"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg name "$name" \
	--argjson order "${order:-null}" \
	--arg time "${time:-}" \
	--arg color "${color:-}" \
	--argjson default "${default:-null}" \
	'{
		tandoor: $tandoor,
		name: $name,
		order: $order,
		time: (if $time == "" then null else $time end),
		color: (if $color == "" then null else $color end),
		default: $default
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_meal_type_create >./result.json
