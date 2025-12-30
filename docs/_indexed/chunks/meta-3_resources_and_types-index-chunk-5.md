---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-5
heading_path: ["Resources and resource types", "Get the root job ID (flow ID)"]
chunk_type: prose
tokens: 26
summary: "Get the root job ID (flow ID)"
---

## Get the root job ID (flow ID)
ROOT_JOB_ID=$(curl -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/jobs_u/get_root_job_id/$WM_JOB_ID" | jq -r .)
