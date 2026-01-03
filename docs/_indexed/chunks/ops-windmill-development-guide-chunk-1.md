---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-1
heading_path: ["Windmill Development Guide"]
chunk_type: prose
tokens: 185
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Windmill Development Guide</title>
  <description>This guide covers the essential workflow for developing Windmill scripts in this repository.</description>
  <created_at>2026-01-02T19:55:27.356035</created_at>
  <updated_at>2026-01-02T19:55:27.356035</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="Prerequisites" level="2"/>
    <section name="Workspace Setup" level="2"/>
    <section name="CLI Workflow" level="2"/>
    <section name="Creating Scripts" level="3"/>
    <section name="Syncing with Remote" level="3"/>
    <section name="Running Scripts" level="3"/>
    <section name="Rust Script Structure" level="2"/>
    <section name="Simple Sync Script (Recommended)" level="3"/>
    <section name="Key Points" level="3"/>
    <section name="Script YAML Schema" level="3"/>
  </sections>
  <features>
    <feature>cargo_not_found_error</feature>
    <feature>cli_workflow</feature>
    <feature>creating_scripts</feature>
    <feature>cross-container_networking</feature>
    <feature>docker_setup</feature>
    <feature>file_structure</feature>
    <feature>js_resp</feature>
    <feature>key_points</feature>
    <feature>network_connectivity</feature>
    <feature>openssl_build_errors</feature>
    <feature>prerequisites</feature>
    <feature>required_image</feature>
    <feature>resources</feature>
    <feature>running_scripts</feature>
    <feature>rust_main</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">anyhow</dependency>
    <dependency type="crate">serde</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,advanced,operations</tags>
</doc_metadata>
-->

# Windmill Development Guide

> **Context**: This guide covers the essential workflow for developing Windmill scripts in this repository.

This guide covers the essential workflow for developing Windmill scripts in this repository.
