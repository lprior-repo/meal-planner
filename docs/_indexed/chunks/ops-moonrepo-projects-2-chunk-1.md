---
doc_id: ops/moonrepo/projects-2
chunk_id: ops/moonrepo/projects-2#chunk-1
heading_path: ["sync projects"]
chunk_type: prose
tokens: 241
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>sync projects</title>
  <description>The `moon sync projects` command will force sync *all* projects in the workspace to help achieve a [healthy repository state](/docs/faq#what-should-be-considered-the-source-of-truth). This applies the</description>
  <created_at>2026-01-02T19:55:26.942020</created_at>
  <updated_at>2026-01-02T19:55:26.942020</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/faq</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>sync,operations,moonrepo</tags>
</doc_metadata>
-->

# sync projects

> **Context**: The `moon sync projects` command will force sync *all* projects in the workspace to help achieve a [healthy repository state](/docs/faq#what-should-be

v1.8.0

The `moon sync projects` command will force sync *all* projects in the workspace to help achieve a [healthy repository state](/docs/faq#what-should-be-considered-the-source-of-truth). This applies the following:

- Ensures cross-project dependencies are linked based on [`dependsOn`](/docs/config/project#dependson).
- Ensures language specific configuration files are present and accurate (`package.json`, `tsconfig.json`, etc).
- Ensures root configuration and project configuration are in sync.
- Any additional language specific semantics that may be required.

```
$ moon sync projects
```

> This command should rarely be ran, as [`moon run`](/docs/commands/run) will sync affected projects automatically! However, when migrating or refactoring, manual syncing may be necessary.
