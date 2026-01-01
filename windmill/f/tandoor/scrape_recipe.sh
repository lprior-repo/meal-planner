# shellcheck shell=bash
# Scrape recipe from URL via Tandoor API
# Arguments: tandoor (resource), url (string)

tandoor="$1"
url="$2"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--arg url "$url" \
	'{tandoor: $tandoor, url: $url}')

# Call binary and capture output
echo "$input" | /usr/local/bin/meal-planner/tandoor_scrape_recipe >./result.json
