---
doc_id: ref/script_editor/job-debouncing
chunk_id: ref/script_editor/job-debouncing#chunk-1
heading_path: ["Job debouncing"]
chunk_type: prose
tokens: 159
summary: "Job debouncing"
---

# Job debouncing

> **Context**: Job debouncing limits job duplicates. When a script is queued with the same debouncing key within the specified time window, only the most recent one 

Job debouncing limits job duplicates. When a script is queued with the same debouncing key within the specified time window, only the most recent one will run. This helps prevent duplicate executions and reduces unnecessary API calls.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only feature.

Job debouncing can be set from the Settings menu. When jobs share the same debouncing key within the time window, earlier jobs are automatically cancelled as "debounced" and only the latest job runs.

The Job debouncing feature operates globally and involves two key parameters:
