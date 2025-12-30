---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-1
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents"]
chunk_type: prose
tokens: 261
summary: "<!--"
---

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
