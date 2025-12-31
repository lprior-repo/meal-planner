# shellcheck shell=bash
# Create a new FatSecret exercise entry
# Arguments: fatsecret (resource), access_token (string), access_secret (string), exercise_id (string), duration_min (number), date_int (number)

fatsecret="$1"
access_token="$2"
access_secret="$3"
exercise_id="$4"
duration_min="$5"
date_int="$6"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg exercise_id "$exercise_id" \
	--argjson duration_min "$duration_min" \
	--argjson date_int "$date_int" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, exercise_id: $exercise_id, duration_min: $duration_min, date_int: $date_int}')

echo "$input" | /usr/local/bin/fatsecret_exercise_entry_create >./result.json
