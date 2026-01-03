---
doc_id: ops/moonrepo/target
chunk_id: ops/moonrepo/target#chunk-1
heading_path: ["Targets"]
chunk_type: code
tokens: 239
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Targets</title>
  <description>A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:task`.</description>
  <created_at>2026-01-02T19:55:26.970349</created_at>
  <updated_at>2026-01-02T19:55:26.970349</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Common scopes" level="2"/>
    <section name="By project" level="3"/>
    <section name="By tag (v1.4.0)" level="3"/>
    <section name="Run scopes" level="2"/>
    <section name="All projects" level="3"/>
    <section name="Closest project `~` (v1.33.0)" level="3"/>
    <section name="Config scopes" level="2"/>
    <section name="Dependencies `^`" level="3"/>
    <section name="Self `~`" level="3"/>
  </sections>
  <features>
    <feature>all_projects</feature>
    <feature>by_project</feature>
    <feature>by_tag_v140</feature>
    <feature>closest_project_v1330</feature>
    <feature>common_scopes</feature>
    <feature>config_scopes</feature>
    <feature>dependencies_</feature>
    <feature>run_scopes</feature>
    <feature>self_</feature>
  </features>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>targets,operations,moonrepo</tags>
</doc_metadata>
-->

# Targets

> **Context**: A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:t

A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:task`.

Targets are used by terminal commands...

```bash
$ moon run designSystem:build
```

And configurations for declaring cross-project or cross-task dependencies.

```yaml
tasks:
  build:
    command: 'webpack'
    deps:
      - 'designSystem:build'
```
