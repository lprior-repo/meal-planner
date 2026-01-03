---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-1
heading_path: ["Architecture"]
chunk_type: prose
tokens: 202
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>core</category>
  <title>Architecture</title>
  <description>Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.</description>
  <created_at>2026-01-02T19:55:26.819178</created_at>
  <updated_at>2026-01-02T19:55:26.819178</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Design Principles (CUPID)" level="2"/>
    <section name="Project Structure" level="2"/>
    <section name="Binary Contract" level="2"/>
    <section name="Example" level="3"/>
    <section name="Domains (Bounded Contexts)" level="2"/>
    <section name="Windmill Integration" level="2"/>
    <section name="Deployment" level="2"/>
    <section name="Adding a New Domain" level="2"/>
    <section name="Testing" level="2"/>
  </sections>
  <features>
    <feature>adding_a_new_domain</feature>
    <feature>binary_contract</feature>
    <feature>deployment</feature>
    <feature>design_principles_cupid</feature>
    <feature>domains_bounded_contexts</feature>
    <feature>example</feature>
    <feature>js_config</feature>
    <feature>js_mut</feature>
    <feature>project_structure</feature>
    <feature>rust_main</feature>
    <feature>testing</feature>
    <feature>windmill_integration</feature>
  </features>
  <dependencies>
    <dependency type="crate">serde</dependency>
    <dependency type="feature">ops/general/moon-ci-pipeline</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,rust,architecture,operations</tags>
</doc_metadata>
-->

# Architecture

> **Context**: Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.

Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.

**For both humans and AI agents**: This doc links to related docs so you can follow the thread without getting lost.
