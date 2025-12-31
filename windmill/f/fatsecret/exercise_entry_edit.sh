# shellcheck shell=bash
# Edit an existing FatSecret exercise entry
# Arguments: fatsecret (resource), access_token (string), access_secret (string), exercise_entry_id (string), exercise_id (string, optional), duration_min (number, optional)

fatsecret="$1"
access_token="$2"
access_secret="$3"
exercise_entry_id="$4"
exercise_id="$5"
duration_min="$6"

# Build input JSON with optional fields
input=$(jq -n \
	--argjson fatsecret "$fatsecret" \
	--arg access_token "$access_token" \
	--arg access_secret "$access_secret" \
	--arg exercise_entry_id "$exercise_entry_id" \
	--arg exercise_id "$exercise_id" \
	--arg duration_min "$duration_min" \
	'{fatsecret: $fatsecret, access_token: $access_token, access_secret: $access_secret, exercise_entry_id: $exercise_entry_id}
	| if $exercise_id != "" then . + {exercise_id: $exercise_id} else . end
	| if $duration_min != "" then . + {duration_min: ($duration_min | tonumber)} else . end')

echo "$input" | /usr/local/bin/fatsecret_exercise_entry_edit >./result.json
