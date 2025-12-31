# shellcheck shell=bash
# Find FatSecret food by barcode
# Arguments: fatsecret (resource), barcode (string), barcode_type (optional string)

fatsecret="$1"
barcode="$2"
barcode_type="${3:-}"

if [ -n "$barcode_type" ]; then
	input=$(jq -n --argjson fatsecret "$fatsecret" --arg barcode "$barcode" --arg barcode_type "$barcode_type" \
		'{fatsecret: $fatsecret, barcode: $barcode, barcode_type: $barcode_type}')
else
	input=$(jq -n --argjson fatsecret "$fatsecret" --arg barcode "$barcode" \
		'{fatsecret: $fatsecret, barcode: $barcode}')
fi

echo "$input" | /usr/local/bin/fatsecret_food_find_barcode >./result.json
