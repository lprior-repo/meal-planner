---
doc_id: ops/moonrepo/node-handbook
chunk_id: ops/moonrepo/node-handbook#chunk-1
heading_path: ["Node.js handbook"]
chunk_type: prose
tokens: 287
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Node.js handbook</title>
  <description>Utilizing JavaScript (and TypeScript) in a monorepo can be a daunting task, especially when using Node.js, as there are many ways to structure your code and to configure your tools. With this handbook</description>
  <created_at>2026-01-02T19:55:27.137352</created_at>
  <updated_at>2026-01-02T19:55:27.137352</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="moon setup" level="2"/>
    <section name="Enabling the language" level="3"/>
    <section name="Utilizing the toolchain" level="3"/>
    <section name="Using `package.json` scripts" level="3"/>
    <section name="Repository structure" level="2"/>
    <section name="Applications" level="3"/>
    <section name="Packages" level="3"/>
    <section name="Configuration" level="3"/>
    <section name="Dependency management" level="2"/>
    <section name="Workspace commands" level="3"/>
  </sections>
  <features>
    <feature>applications</feature>
    <feature>bundler_integration</feature>
    <feature>code_sharing</feature>
    <feature>configuration</feature>
    <feature>dependency_management</feature>
    <feature>depending_on_packages</feature>
    <feature>developer_tools_at_the_root</feature>
    <feature>enabling_the_language</feature>
    <feature>externally_published</feature>
    <feature>internally_published</feature>
    <feature>js_path</feature>
    <feature>local_only</feature>
    <feature>moon_setup</feature>
    <feature>packages</feature>
    <feature>product_libraries_in_a_project</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/moon</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="18">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>11</estimated_reading_time>
  <tags>advanced,operations,javascript,typescript,nodejs</tags>
</doc_metadata>
-->

# Node.js handbook

> **Context**: Utilizing JavaScript (and TypeScript) in a monorepo can be a daunting task, especially when using Node.js, as there are many ways to structure your co

Utilizing JavaScript (and TypeScript) in a monorepo can be a daunting task, especially when using Node.js, as there are many ways to structure your code and to configure your tools. With this handbook, we'll help guide you through this process.

info

This guide is a living document and will continue to be updated over time!
