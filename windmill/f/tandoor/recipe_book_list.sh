# shellcheck shell=bash
# List recipe books from Tandoor with pagination

tandoor="$1"
page="${2:-}"
page_size="${3:-}"

# Build JSON input for binary with optional fields
if [ -n "$page" ] && [ -n "$page_size" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson page "$page" \
		--argjson page_size "$page_size" \
		'{tandoor: $tandoor, page: $page, page_size: $page_size}')
elif [ -n "$page" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson page "$page" \
		'{tandoor: $tandoor, page: $page}')
elif [ -n "$page_size" ]; then
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		--argjson page_size "$page_size" \
		'{tandoor: $tandoor, page_size: $page_size}')
else
	input=$(jq -n \
		--argjson tandoor "$tandoor" \
		'{tandoor: $tandoor}')
fi

echo "$input" | /usr/local/bin/meal-planner/tandoor_recipe_book_list >./result.json
