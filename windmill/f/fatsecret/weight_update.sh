# shellcheck shell=bash
# Update FatSecret weight measurement
# Arguments: fatsecret (resource), access_token (string), access_secret (string), current_weight_kg (number), date_int (integer), goal_weight_kg (number), height_cm (number), comment (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
current_weight_kg="$4"
date_int="$5"
goal_weight_kg="$6"
height_cm="$7"
comment="$8"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--argjson current_weight_kg "$current_weight_kg" \
	--argjson date_int "$date_int" \
	--arg goal_weight_kg "$goal_weight_kg" \
	--arg height_cm "$height_cm" \
	--arg comment "$comment" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, current_weight_kg: $current_weight_kg, date_int: $date_int, goal_weight_kg: (if $goal_weight_kg == "" then null else ($goal_weight_kg | tonumber) end), height_cm: (if $height_cm == "" then null else ($height_cm | tonumber) end), comment: (if $comment == "" then null else $comment end)}')

echo "$input" | /usr/local/bin/fatsecret_weight_update >./result.json
