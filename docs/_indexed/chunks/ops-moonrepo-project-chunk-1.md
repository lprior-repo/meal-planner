---
doc_id: ops/moonrepo/project
chunk_id: ops/moonrepo/project#chunk-1
heading_path: ["project"]
chunk_type: prose
tokens: 283
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>moon.{pkl,yml}</title>
  <description>The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at the project-level. When used, this file must exis</description>
  <created_at>2026-01-02T19:55:26.990780</created_at>
  <updated_at>2026-01-02T19:55:26.990780</updated_at>
  <language>en</language>
  <sections count="51">
    <section name="`dependsOn`" level="2"/>
    <section name="Metadata" level="2"/>
    <section name="`id` (v1.18.0)" level="2"/>
    <section name="`language`" level="2"/>
    <section name="`layer`" level="2"/>
    <section name="`project`" level="2"/>
    <section name="`channel`" level="3"/>
    <section name="`description` (Required)" level="3"/>
    <section name="`maintainers`" level="3"/>
    <section name="`metadata` (v1.27.0)" level="3"/>
  </sections>
  <features>
    <feature>args</feature>
    <feature>channel</feature>
    <feature>command</feature>
    <feature>default_v1310</feature>
    <feature>deno</feature>
    <feature>dependson</feature>
    <feature>deps</feature>
    <feature>description_required</feature>
    <feature>description_v1220</feature>
    <feature>disabled</feature>
    <feature>exclude</feature>
    <feature>extends_v1120</feature>
    <feature>filegroups</feature>
    <feature>id_v1180</feature>
    <feature>include</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/pkl-config</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/task-inheritance</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="37">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>13</estimated_reading_time>
  <tags>moonpklyml,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# moon.{pkl,yml}

> **Context**: The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at

The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at the project-level. When used, this file must exist in a project's root, as configured in [`projects`](/docs/config/workspace#projects).

moon.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/project.json'
```

> Project configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
