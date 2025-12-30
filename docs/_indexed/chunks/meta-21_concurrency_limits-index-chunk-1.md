---
doc_id: meta/21_concurrency_limits/index
chunk_id: meta/21_concurrency_limits/index#chunk-1
heading_path: ["Concurrency limits"]
chunk_type: prose
tokens: 241
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Concurrency Limits</title>
  <description>Prevent exceeding API rate limits by controlling execution frequency</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Concurrency limits" level="1"/>
    <section name="Max number of executions within time window" level="2"/>
    <section name="Time window in seconds" level="2"/>
    <section name="Custom concurrency key" level="2"/>
  </sections>
  <features>
    <feature>concurrency_limits</feature>
    <feature>rate_limiting</feature>
    <feature>throttling</feature>
    <feature>api_protection</feature>
  </features>
  <dependencies>
    <dependency type="feature">enterprise_edition</dependency>
  </dependencies>
  <examples count="3">
    <example>API rate limit protection</example>
    <example>Database connection pool management</example>
    <example>External service throttling</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,concurrency,limit,rate-limit,API,throttle,queue</tags>
</doc_metadata>
-->

# Concurrency limits

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>core_concepts</category> <title>Concurrency Limits</title> <description>Prevent exceeding API rat

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:
