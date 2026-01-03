---
doc_id: ops/moonrepo/setup-toolchain
chunk_id: ops/moonrepo/setup-toolchain#chunk-1
heading_path: ["Setup toolchain"]
chunk_type: prose
tokens: 211
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Setup toolchain</title>
  <description>One of moon&apos;s most powerful features is the toolchain, which automatically manages, downloads, and installs Node.js and other languages behind the scenes using proto. It also enables advanced function</description>
  <created_at>2026-01-02T19:55:27.232697</created_at>
  <updated_at>2026-01-02T19:55:27.232697</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="How it works" level="2"/>
    <section name="Enabling a platform" level="2"/>
    <section name="Automatically installing a tool" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>automatically_installing_a_tool</feature>
    <feature>enabling_a_platform</feature>
    <feature>how_it_works</feature>
    <feature>next_steps</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/create-task</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>setup,operations,moonrepo</tags>
</doc_metadata>
-->

# Setup toolchain

> **Context**: One of moon's most powerful features is the toolchain, which automatically manages, downloads, and installs Node.js and other languages behind the sce

One of moon's most powerful features is the toolchain, which automatically manages, downloads, and installs Node.js and other languages behind the scenes using proto. It also enables advanced functionality for task running based on the platform (language and environment combination) it runs in.

The toolchain is configured with `.moon/toolchain.yml`.
