---
doc_id: ops/moonrepo/setup-workspace
chunk_id: ops/moonrepo/setup-workspace#chunk-1
heading_path: ["Setup workspace"]
chunk_type: prose
tokens: 243
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Setup workspace</title>
  <description>Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace is in charge of:</description>
  <created_at>2026-01-02T19:55:27.234897</created_at>
  <updated_at>2026-01-02T19:55:27.234897</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Initializing the repository" level="2"/>
    <section name="Migrate from an existing build system" level="2"/>
    <section name="Configuring a version control system" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>configuring_a_version_control_system</feature>
    <feature>initializing_the_repository</feature>
    <feature>migrate_from_an_existing_build_system</feature>
    <feature>next_steps</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/create-project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/workspace</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>setup,operations,moonrepo</tags>
</doc_metadata>
-->

# Setup workspace

> **Context**: Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace

Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace is in charge of:

-   Integrating with a version control system.
-   Defining configuration that applies to its entire tree.
-   Housing projects to build a project graph.
-   Running tasks with the action graph.
