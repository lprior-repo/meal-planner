---
doc_id: concept/windmill/8-error-handling
chunk_id: concept/windmill/8-error-handling#chunk-1
heading_path: ["Error handling in flows"]
chunk_type: prose
tokens: 130
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Error handling in flows</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.996687</created_at>
  <updated_at>2026-01-02T19:55:27.996687</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Error handler" level="2"/>
    <section name="Retries" level="2"/>
    <section name="Early stop / Break" level="2"/>
    <section name="Custom timeout for step" level="2"/>
    <section name="Error handling" level="2"/>
  </sections>
  <features>
    <feature>custom_timeout_for_step</feature>
    <feature>early_stop_break</feature>
    <feature>error_handler</feature>
    <feature>error_handling</feature>
    <feature>retries</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/windmill/14-retries</dependency>
    <dependency type="feature">tutorial/windmill/7-flow-error-handler</dependency>
    <dependency type="feature">concept/windmill/2-early-stop</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./14_retries.md</entity>
    <entity relationship="uses">./7_flow_error_handler.md</entity>
    <entity relationship="uses">./2_early_stop.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,concept,error</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Error handling in flows

> **Context**: import DocCard from '@site/src/components/DocCard';

There are four ways to handle errors in Windmill flows: [retries](./ops-windmill-14-retries.md), [error handlers](./tutorial-windmill-7-flow-error-handler.md), and [early stop/break](./concept-windmill-2-early-stop.md).
