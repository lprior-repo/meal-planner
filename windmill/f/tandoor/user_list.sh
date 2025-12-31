# shellcheck shell=bash
# List users from Tandoor
# Arguments: tandoor (resource), page (number, optional), page_size (number, optional)

tandoor="$1"
page="${2:-null}"
page_size="${3:-null}"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson page "$page" \
	--argjson page_size "$page_size" \
	'{tandoor: $tandoor, page: $page, page_size: $page_size}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_user_list >./result.json
