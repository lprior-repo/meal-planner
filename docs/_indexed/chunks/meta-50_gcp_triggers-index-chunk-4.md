---
doc_id: meta/50_gcp_triggers/index
chunk_id: meta/50_gcp_triggers/index#chunk-4
heading_path: ["GCP Pub/Sub triggers", "Troubleshooting"]
chunk_type: prose
tokens: 111
summary: "Troubleshooting"
---

## Troubleshooting

- **Permission issues**: Verify the service account has required Pub/Sub permissions. If the correct permissions are set but you still encounter `unauthorized` or `permission denied` errors, it might indicate that Google has updated required permissions. Please contact Windmill support so we can investigate and assist.
- **Push delivery failures**: If using existing subscription ensure the push endpoint URL matches the required format (`{base_endpoint}/api/gcp/w/{workspace_id}/{trigger_path}`) and is unique across the workspace.
- **Topic or subscription not found**: Refresh the list to fetch the latest available resources.
