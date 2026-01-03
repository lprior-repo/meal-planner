---
doc_id: tutorial/windmill/22-while-loops
chunk_id: tutorial/windmill/22-while-loops#chunk-1
heading_path: ["While loops"]
chunk_type: prose
tokens: 185
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>While loops</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.970199</created_at>
  <updated_at>2026-01-02T19:55:27.970199</updated_at>
  <language>en</language>
  <sections count="13">
    <section name="How to stop a while loop" level="2"/>
    <section name="Cancel manually" level="3"/>
    <section name="Early stop / Break" level="3"/>
    <section name="Early stop for step" level="3"/>
    <section name="Skip failure" level="2"/>
    <section name="Squash" level="2"/>
    <section name="Test an iteration" level="2"/>
    <section name="Advanced settings" level="2"/>
    <section name="Early stop / Break" level="3"/>
    <section name="Suspend/Approval/Prompt" level="3"/>
  </sections>
  <features>
    <feature>advanced_settings</feature>
    <feature>cancel_manually</feature>
    <feature>early_stop_break</feature>
    <feature>early_stop_for_step</feature>
    <feature>how_to_stop_a_while_loop</feature>
    <feature>lifetime</feature>
    <feature>mock</feature>
    <feature>skip_failure</feature>
    <feature>sleep</feature>
    <feature>squash</feature>
    <feature>suspendapprovalprompt</feature>
    <feature>test_an_iteration</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-76</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-41</dependency>
    <dependency type="feature">meta/windmill/index-39</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/5_monitor_past_and_future_runs/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../core_concepts/25_dedicated_workers/index.mdx</entity>
    <entity relationship="uses">../core_concepts/23_instant_preview/index.mdx</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,while</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# While loops

> **Context**: import DocCard from '@site/src/components/DocCard';

While loops execute a sequence of code indefinitely until the user cancels or a step set to Early stop stops.
