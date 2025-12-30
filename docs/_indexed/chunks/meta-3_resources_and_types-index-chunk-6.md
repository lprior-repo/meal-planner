---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-6
heading_path: ["Resources and resource types", "Set flow user state"]
chunk_type: prose
tokens: 29
summary: "Set flow user state"
---

## Set flow user state
curl -s -X POST \
  -H "Authorization: Bearer $WM_TOKEN" \
  -H "Content-Type: application/json" \
  -d '"my_value"' \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/jobs/flow/user_states/$ROOT_JOB_ID/my_key"
