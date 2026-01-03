---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-1
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents"]
chunk_type: prose
tokens: 445
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Windmill Rust SDK: Complete Reference Guide for AI Coding Agents</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;sdk&lt;/category&gt; &lt;title&gt;Windmill Rust SDK: Complete Reference Guide&lt;/title&gt; &lt;description&gt;Complete reference guide for Windmill Rust scripts including</description>
  <created_at>2026-01-02T19:55:27.906817</created_at>
  <updated_at>2026-01-02T19:55:27.906817</updated_at>
  <language>en</language>
  <sections count="43">
    <section name="SDK fundamentals and crate setup" level="2"/>
    <section name="Inline dependency declaration" level="3"/>
    <section name="Environment variables automatically available" level="3"/>
    <section name="Main function signature patterns" level="2"/>
    <section name="Basic synchronous script" level="3"/>
    <section name="Async script with SDK access" level="3"/>
    <section name="Parameter type mappings" level="3"/>
    <section name="Required versus optional parameters" level="3"/>
    <section name="Complex input types" level="3"/>
    <section name="Return types and output serialization" level="2"/>
  </sections>
  <features>
    <feature>async_script_with_sdk_access</feature>
    <feature>asynchronous_execution_fire_and_forget</feature>
    <feature>basic_synchronous_script</feature>
    <feature>build_modes_and_caching</feature>
    <feature>calling_other_scripts_and_managing_jobs</feature>
    <feature>complete_code_examples</feature>
    <feature>complex_input_types</feature>
    <feature>conclusion</feature>
    <feature>creating_and_updating_resources</feature>
    <feature>custom_error_types_with_thiserror</feature>
    <feature>database_queries_with_tokio-postgres</feature>
    <feature>error_handling_patterns</feature>
    <feature>flow_composition_and_data_passing</feature>
    <feature>how_windmill_surfaces_errors</feature>
    <feature>http_requests_with_reqwest</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">anyhow</dependency>
    <dependency type="crate">serde</dependency>
    <dependency type="library">requests</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
  </dependencies>
  <examples count="36">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>12</estimated_reading_time>
  <tags>windmill,rust,advanced,operations</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>sdk</category>
  <title>Windmill Rust SDK: Complete Reference Guide</title>
  <description>Complete reference guide for Windmill Rust scripts including SDK fundamentals, patterns, resources, state, and job management</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="SDK fundamentals and crate setup" level="1"/>
    <section name="Main function signature patterns" level="1"/>
    <section name="Return types and output serialization" level="1"/>
    <section name="Resource and secret access" level="1"/>
    <section name="State management between runs" level="1"/>
    <section name="Calling other scripts and managing jobs" level="1"/>
    <section name="Error handling patterns" level="1"/>
    <section name="Flow composition and data passing" level="1"/>
    <section name="Complete code examples" level="1"/>
    <section name="Limitations compared to TypeScript and Python" level="1"/>
  </sections>
  <features>
    <feature>rust_sdk</feature>
    <feature>wmill</feature>
    <feature>windmill_resources</feature>
    <feature>windmill_state</feature>
    <feature>windmill_jobs</feature>
    <feature>error_handling</feature>
    <feature>flow_composition</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">anyhow</dependency>
    <dependency type="crate">serde</dependency>
  </dependencies>
  <code_examples count="10</code_examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>20</estimated_reading_time>
  <tags>windmill,rust,sdk,wmill,crate,anyhow,tokio,serde,resources,state,jobs</tags>
</doc_metadata>
-->

# Windmill Rust SDK: Complete Reference Guide for AI Coding Agents

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>sdk</category> <title>Windmill Rust SDK: Complete Reference Guide</title> <description>Complete r

Windmill's Rust support, introduced in August 2024, enables high-performance script execution with full SDK access for resources, state, and inter-script communication. The `wmill` crate (v1.601.1) provides typed API access, while scripts use a distinctive inline Cargo.toml format within doc comments. This guide covers every pattern needed to write production Windmill Rust scripts.

---
