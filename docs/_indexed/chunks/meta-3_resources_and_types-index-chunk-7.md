---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-7
heading_path: ["Resources and resource types", "Get flow user state"]
chunk_type: prose
tokens: 39
summary: "Get flow user state"
---

## Get flow user state
VALUE=$(curl -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/jobs/flow/user_states/$ROOT_JOB_ID/my_key")

echo "Retrieved value: $VALUE"
```

</TabItem>
</Tabs>

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_state.mp4"
/>
