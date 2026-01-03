---
doc_id: ops/moonrepo/wasm-plugins
chunk_id: ops/moonrepo/wasm-plugins#chunk-1
heading_path: ["WASM plugins"]
chunk_type: prose
tokens: 301
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>WASM plugins</title>
  <description>[moon](/moon) and [proto](/proto) plugins can be written in [WebAssembly (WASM)](https://webassembly.org/), a portable binary format. This means that plugins can be written in any language that compil</description>
  <created_at>2026-01-02T19:55:27.207549</created_at>
  <updated_at>2026-01-02T19:55:27.207549</updated_at>
  <language>en</language>
  <sections count="21">
    <section name="Powered by Extism" level="2"/>
    <section name="Concepts" level="2"/>
    <section name="Plugin identifier" level="3"/>
    <section name="Virtual paths" level="3"/>
    <section name="File system caveats" level="4"/>
    <section name="Host environment" level="3"/>
    <section name="Host functions &amp; macros" level="3"/>
    <section name="Converting paths" level="4"/>
    <section name="Environment variables" level="4"/>
    <section name="Executing commands" level="4"/>
  </sections>
  <features>
    <feature>automate_releases</feature>
    <feature>building_and_publishing</feature>
    <feature>building_optimizing_and_stripping</feature>
    <feature>concepts</feature>
    <feature>configuring_plugin_locations</feature>
    <feature>converting_paths</feature>
    <feature>creating_a_plugin</feature>
    <feature>environment_variables</feature>
    <feature>executing_commands</feature>
    <feature>file</feature>
    <feature>file_system_caveats</feature>
    <feature>github</feature>
    <feature>host_environment</feature>
    <feature>host_functions_macros</feature>
    <feature>https</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/moon</entity>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="31">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>11</estimated_reading_time>
  <tags>advanced,operations,wasm,typescript,rust</tags>
</doc_metadata>
-->

# WASM plugins

> **Context**: [moon](/moon) and [proto](/proto) plugins can be written in [WebAssembly (WASM)](https://webassembly.org/), a portable binary format. This means that 

[moon](/moon) and [proto](/proto) plugins can be written in [WebAssembly (WASM)](https://webassembly.org/), a portable binary format. This means that plugins can be written in any language that compiles to WASM, like Rust, C, C++, Go, TypeScript, and more. Because WASM based plugins are powered by a programming language, they implicitly support complex business logic and behavior, have access to a sandboxed file system (via WASI), can execute child processes, and much more.

> **Danger:** Since our WASM plugin implementations are still experimental, expect breaking changes to occur in non-major releases.
