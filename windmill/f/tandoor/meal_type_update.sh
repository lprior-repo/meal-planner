# shellcheck shell=bash
# Update a meal type in Tandoor
# Arguments: tandoor (resource), id (number), name (optional), order (optional), time (optional), color (optional), default (optional)

tandoor="$1"
id="$2"
name="$3"
order="$4"
time="$5"
color="$6"
default="$7"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson id "$id" \
	--arg name "${name:-}" \
	--argjson order "${order:-null}" \
	--arg time "${time:-}" \
	--arg color "${color:-}" \
	--argjson default "${default:-null}" \
	'{
		tandoor: $tandoor,
		id: $id,
		name: (if $name == "" then null else $name end),
		order: $order,
		time: (if $time == "" then null else $time end),
		color: (if $color == "" then null else $color end),
		default: $default
	}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_meal_type_update >./result.json
