---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-1
heading_path: [".moon/workspace.{pkl,yml}"]
chunk_type: prose
tokens: 221
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>.moon/workspace.{pkl,yml}</title>
  <description>The `.moon/workspace.yml` file configures projects and services in the workspace. This file is *required*.</description>
  <created_at>2026-01-02T19:55:27.021779</created_at>
  <updated_at>2026-01-02T19:55:27.021779</updated_at>
  <language>en</language>
  <sections count="33">
    <section name="`extends`" level="2"/>
    <section name="`projects` (Required)" level="2"/>
    <section name="Using a map" level="3"/>
    <section name="Using globs" level="3"/>
    <section name="Using a map *and* globs" level="3"/>
    <section name="`codeowners` (v1.8.0)" level="2"/>
    <section name="`globalPaths`" level="3"/>
    <section name="`syncOnRun`" level="3"/>
    <section name="`constraints`" level="2"/>
    <section name="`enforceLayerRelationships`" level="3"/>
  </sections>
  <features>
    <feature>cachelifetime</feature>
    <feature>codeowners_v180</feature>
    <feature>constraints</feature>
    <feature>defaultbranch</feature>
    <feature>docker_v1270</feature>
    <feature>enforcelayerrelationships</feature>
    <feature>extends</feature>
    <feature>generator</feature>
    <feature>globalpaths</feature>
    <feature>hasher</feature>
    <feature>hooks_v190</feature>
    <feature>host</feature>
    <feature>inheritcolorsforpipedtasks</feature>
    <feature>manager</feature>
    <feature>notifier</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/guides/pkl-config</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/concepts/file-pattern</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
  </related_entities>
  <examples count="21">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>7</estimated_reading_time>
  <tags>moonworkspacepklyml,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# .moon/workspace.{pkl,yml}

> **Context**: The `.moon/workspace.yml` file configures projects and services in the workspace. This file is *required*.

The `.moon/workspace.yml` file configures projects and services in the workspace. This file is *required*.

.moon/workspace.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/workspace.json'
```

> Workspace configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
