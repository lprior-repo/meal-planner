# shellcheck shell=bash
# Update a recipe in Tandoor
# Arguments: tandoor (resource), recipe_id (integer), name (string, optional),
#            description (string, optional), source_url (string, optional),
#            servings (integer, optional), working_time (integer, optional),
#            waiting_time (integer, optional)

tandoor="$1"
recipe_id="$2"
name="${3:-}"
description="${4:-}"
source_url="${5:-}"
servings="${6:-}"
working_time="${7:-}"
waiting_time="${8:-}"

# Start with required fields
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson recipe_id "$recipe_id" \
	'{tandoor: $tandoor, recipe_id: $recipe_id}')

# Add optional fields if provided
if [ -n "$name" ]; then
	input=$(echo "$input" | jq --arg name "$name" '. + {name: $name}')
fi
if [ -n "$description" ]; then
	input=$(echo "$input" | jq --arg description "$description" '. + {description: $description}')
fi
if [ -n "$source_url" ]; then
	input=$(echo "$input" | jq --arg source_url "$source_url" '. + {source_url: $source_url}')
fi
if [ -n "$servings" ]; then
	input=$(echo "$input" | jq --argjson servings "$servings" '. + {servings: $servings}')
fi
if [ -n "$working_time" ]; then
	input=$(echo "$input" | jq --argjson working_time "$working_time" '. + {working_time: $working_time}')
fi
if [ -n "$waiting_time" ]; then
	input=$(echo "$input" | jq --argjson waiting_time "$waiting_time" '. + {waiting_time: $waiting_time}')
fi

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_update >./result.json
