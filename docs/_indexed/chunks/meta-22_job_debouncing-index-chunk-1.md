---
doc_id: meta/22_job_debouncing/index
chunk_id: meta/22_job_debouncing/index#chunk-1
heading_path: ["Job debouncing"]
chunk_type: prose
tokens: 232
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Job Debouncing</title>
  <description>Prevents redundant job executions by canceling pending jobs with identical characteristics</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Job debouncing" level="1"/>
    <section name="Debounce delay in seconds" level="2"/>
    <section name="Custom debounce key" level="2"/>
    <section name="Dependency jobs" level="2"/>
    <section name="Job debouncing in Script & Flows" level="2"/>
  </sections>
  <features>
    <feature>job_debouncing</feature>
    <feature>duplicate_prevention</feature>
    <feature>resource_optimization</feature>
    <feature>auto_cancellation</feature>
  </features>
  <dependencies>
    <dependency type="feature">enterprise_edition</dependency>
  </dependencies>
  <examples count="2">
    <example>Prevent duplicate API calls</example>
    <example>Optimize workflow triggers</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,debounce,cancel,pending,duplicate,jobs,optimization</tags>
</doc_metadata>
-->

# Job debouncing

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>core_concepts</category> <title>Job Debouncing</title> <description>Prevents redundant job execut

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window. This feature helps optimize resource usage and prevents unnecessary duplicate computations.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Debouncing can be set from the Settings menu. When jobs with matching characteristics are submitted within the debounce window, pending jobs are automatically canceled in favor of the newest one.

The Job debouncing operates globally and across flow runs. It involves two key parameters:
