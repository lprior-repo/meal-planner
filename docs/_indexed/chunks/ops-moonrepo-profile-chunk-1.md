---
doc_id: ops/moonrepo/profile
chunk_id: ops/moonrepo/profile#chunk-1
heading_path: ["Task profiling"]
chunk_type: prose
tokens: 221
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Task profiling</title>
  <description>Troubleshooting slow or unperformant tasks? Profile and diagnose them with ease!</description>
  <created_at>2026-01-02T19:55:27.187153</created_at>
  <updated_at>2026-01-02T19:55:27.187153</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="CPU snapshots" level="2"/>
    <section name="Record a profile" level="3"/>
    <section name="Analyze in Chrome" level="3"/>
    <section name="Heap snapshots" level="2"/>
    <section name="Record a profile" level="3"/>
    <section name="Analyze in Chrome" level="3"/>
    <section name="Views" level="2"/>
    <section name="Bottom up" level="3"/>
    <section name="Top down" level="3"/>
    <section name="Flame chart" level="3"/>
  </sections>
  <features>
    <feature>analyze_in_chrome</feature>
    <feature>bottom_up</feature>
    <feature>cpu_snapshots</feature>
    <feature>flame_chart</feature>
    <feature>heap_snapshots</feature>
    <feature>record_a_profile</feature>
    <feature>top_down</feature>
    <feature>views</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>task,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Task profiling

> **Context**: Troubleshooting slow or unperformant tasks? Profile and diagnose them with ease!

Troubleshooting slow or unperformant tasks? Profile and diagnose them with ease!

> **Caution:** Profiling is only supported by `node` based tasks, and is not supported by tasks that are created through `package.json` inference, or for packages that ship non-JavaScript code (like Rust or Go).
