---
doc_id: ops/moonrepo/codegen
chunk_id: ops/moonrepo/codegen#chunk-1
heading_path: ["Code generation"]
chunk_type: prose
tokens: 289
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Code generation</title>
  <description>Code generation provides an easy mechanism for automating common development workflows and file structures. Whether it&apos;s scaffolding a new library or application, updating configuration, or standardiz</description>
  <created_at>2026-01-02T19:55:27.054703</created_at>
  <updated_at>2026-01-02T19:55:27.054703</updated_at>
  <language>en</language>
  <sections count="22">
    <section name="Creating a new template" level="2"/>
    <section name="Configuring `template.yml`" level="3"/>
    <section name="Managing files" level="3"/>
    <section name="Interpolation" level="4"/>
    <section name="File extensions" level="4"/>
    <section name="Partials" level="4"/>
    <section name="Raws (v1.11.0)" level="4"/>
    <section name="Frontmatter" level="4"/>
    <section name="Assets" level="4"/>
    <section name="Template engine &amp; syntax" level="3"/>
  </sections>
  <features>
    <feature>archive_urls_v1360</feature>
    <feature>assets</feature>
    <feature>configuring_template_locations</feature>
    <feature>configuring_templateyml</feature>
    <feature>creating_a_new_template</feature>
    <feature>declaring_variables_with_cli_arguments</feature>
    <feature>file_extensions</feature>
    <feature>filters</feature>
    <feature>frontmatter</feature>
    <feature>functions</feature>
    <feature>generating_code_from_a_template</feature>
    <feature>git_and_npm_layout_structure</feature>
    <feature>git_repositories_v1230</feature>
    <feature>globs_v1310</feature>
    <feature>interpolation</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses">/docs/config/template</entity>
  </related_entities>
  <examples count="20">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>9</estimated_reading_time>
  <tags>code,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Code generation

> **Context**: Code generation provides an easy mechanism for automating common development workflows and file structures. Whether it's scaffolding a new library or 

Code generation provides an easy mechanism for automating common development workflows and file structures. Whether it's scaffolding a new library or application, updating configuration, or standardizing patterns.

To accomplish this, we provide a generator, which is divided into two parts. The first being the templates and their files to be scaffolded. The second is our rendering engine that writes template files to a destination.
