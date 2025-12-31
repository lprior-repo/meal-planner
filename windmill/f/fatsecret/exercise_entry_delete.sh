# shellcheck shell=bash
# Delete a FatSecret exercise entry
# Arguments: fatsecret (resource), access_token (string), access_secret (string), exercise_entry_id (string)

fatsecret="$1"
access_token="$2"
access_secret="$3"
exercise_entry_id="$4"

input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg exercise_entry_id "$exercise_entry_id" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, exercise_entry_id: $exercise_entry_id}')

echo "$input" | /usr/local/bin/fatsecret_exercise_entry_delete >./result.json
