# shellcheck shell=bash
# List keywords from Tandoor
# Arguments: tandoor (resource), page (optional), page_size (optional)

tandoor="$1"
page="$2"
page_size="$3"

# Build JSON input for binary
input=$(jq -n \
	--argjson tandoor "$tandoor" \
	--argjson page "${page:-null}" \
	--argjson page_size "${page_size:-null}" \
	'{tandoor: $tandoor, page: $page, page_size: $page_size}')

# Call binary and capture output
echo "$input" | /usr/local/bin/tandoor_keyword_list >./result.json
