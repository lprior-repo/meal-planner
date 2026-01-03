---
doc_id: ops/windmill/rust-client
chunk_id: ops/windmill/rust-client#chunk-1
heading_path: ["Rust client"]
chunk_type: prose
tokens: 262
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Rust client</title>
  <description>The Rust client library for Windmill provides a convenient way to interact with the Windmill platform&apos;s API from within your Rust applications. By authenticating with the `WM_TOKEN` reserved variable </description>
  <created_at>2026-01-02T19:55:27.469464</created_at>
  <updated_at>2026-01-02T19:55:27.469464</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="Installation" level="2"/>
    <section name="Usage" level="2"/>
    <section name="Usage" level="2"/>
    <section name="Initialize client" level="3"/>
    <section name="Variables" level="3"/>
    <section name="Resources" level="3"/>
    <section name="Scripts" level="3"/>
    <section name="Jobs" level="3"/>
    <section name="State management" level="3"/>
    <section name="Progress tracking" level="3"/>
  </sections>
  <features>
    <feature>custom_api_calls</feature>
    <feature>initialize_client</feature>
    <feature>installation</feature>
    <feature>jobs</feature>
    <feature>js_config</feature>
    <feature>js_db_config</feature>
    <feature>js_job_id</feature>
    <feature>js_progress</feature>
    <feature>js_raw_json</feature>
    <feature>js_raw_state</feature>
    <feature>js_raw_text</feature>
    <feature>js_result</feature>
    <feature>js_state</feature>
    <feature>js_status</feature>
    <feature>js_user</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">serde</dependency>
    <dependency type="service">postgresql</dependency>
  </dependencies>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,api,rust,operations</tags>
</doc_metadata>
-->

# Rust client

> **Context**: The Rust client library for Windmill provides a convenient way to interact with the Windmill platform's API from within your Rust applications. By aut

The Rust client library for Windmill provides a convenient way to interact with the Windmill platform's API from within your Rust applications. By authenticating with the `WM_TOKEN` reserved variable or custom tokens, you can utilize the Rust client to access various functionalities offered by Windmill.

<div className="inline-flex gap-2">
  <a href="https://crates.io/crates/wmill"><img src="https://img.shields.io/crates/v/wmill" alt="crates.io" /></a>
  <a href="https://docs.rs/wmill"><img src="https://img.shields.io/docsrs/wmill" alt="docs.rs" /></a>
</div>
