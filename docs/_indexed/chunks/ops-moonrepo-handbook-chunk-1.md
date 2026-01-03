---
doc_id: ops/moonrepo/handbook
chunk_id: ops/moonrepo/handbook#chunk-1
heading_path: ["Rust handbook"]
chunk_type: prose
tokens: 278
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Rust handbook</title>
  <description>Utilizing Rust in a monorepo is a trivial task, thanks to Cargo, and also moon. With this handbook, we&apos;ll help guide you through this process.</description>
  <created_at>2026-01-02T19:55:27.194925</created_at>
  <updated_at>2026-01-02T19:55:27.194925</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="moon setup" level="2"/>
    <section name="Enabling the language" level="3"/>
    <section name="Utilizing the toolchain" level="3"/>
    <section name="Repository structure" level="2"/>
    <section name="Example `moon.yml`" level="3"/>
    <section name="Cargo integration" level="2"/>
    <section name="Global binaries" level="3"/>
    <section name="Lockfile handling" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="Should we cache the `target` directory as an output?" level="3"/>
  </sections>
  <features>
    <feature>cargo_integration</feature>
    <feature>enabling_the_language</feature>
    <feature>example_moonyml</feature>
    <feature>global_binaries</feature>
    <feature>how_can_we_improve_ci_times</feature>
    <feature>lockfile_handling</feature>
    <feature>moon_setup</feature>
    <feature>repository_structure</feature>
    <feature>utilizing_the_toolchain</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/moon</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
  </related_entities>
  <examples count="10">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>rust,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Rust handbook

> **Context**: Utilizing Rust in a monorepo is a trivial task, thanks to Cargo, and also moon. With this handbook, we'll help guide you through this process.

Utilizing Rust in a monorepo is a trivial task, thanks to Cargo, and also moon. With this handbook, we'll help guide you through this process.

info

moon is not a build system and does *not* replace Cargo. Instead, moon runs `cargo` commands, and efficiently orchestrates those tasks within the workspace.
