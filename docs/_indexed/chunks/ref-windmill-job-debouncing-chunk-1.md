---
doc_id: ref/windmill/job-debouncing
chunk_id: ref/windmill/job-debouncing#chunk-1
heading_path: ["Job debouncing"]
chunk_type: prose
tokens: 249
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>windmill</category>
  <title>Job debouncing</title>
  <description>Job debouncing limits job duplicates. When a script is queued with the same debouncing key within the specified time window, only the most recent one will run. This helps prevent duplicate executions </description>
  <created_at>2026-01-02T19:55:28.169956</created_at>
  <updated_at>2026-01-02T19:55:28.169956</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Debounce delay in seconds" level="2"/>
    <section name="Custom debouncing key" level="2"/>
  </sections>
  <features>
    <feature>custom_debouncing_key</feature>
    <feature>debounce_delay_in_seconds</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/pricing</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,api,job,reference</tags>
</doc_metadata>
-->

# Job debouncing

> **Context**: Job debouncing limits job duplicates. When a script is queued with the same debouncing key within the specified time window, only the most recent one 

Job debouncing limits job duplicates. When a script is queued with the same debouncing key within the specified time window, only the most recent one will run. This helps prevent duplicate executions and reduces unnecessary API calls.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only feature.

Job debouncing can be set from the Settings menu. When jobs share the same debouncing key within the time window, earlier jobs are automatically cancelled as "debounced" and only the latest job runs.

The Job debouncing feature operates globally and involves two key parameters:
