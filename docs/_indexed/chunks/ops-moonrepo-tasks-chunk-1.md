---
doc_id: ops/moonrepo/tasks
chunk_id: ops/moonrepo/tasks#chunk-1
heading_path: ["query tasks"]
chunk_type: prose
tokens: 214
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>query tasks</title>
  <description>Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [query statement](/docs/concepts/query-lang) as an a</description>
  <created_at>2026-01-02T19:55:26.932500</created_at>
  <updated_at>2026-01-02T19:55:26.932500</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Affected" level="4"/>
    <section name="Filters (v1.30.0)" level="4"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>affected</feature>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>filters_v1300</feature>
    <feature>options</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>query,operations,moonrepo</tags>
</doc_metadata>
-->

# query tasks

> **Context**: Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [q

Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [query statement](/docs/concepts/query-lang) as an argument, or by using [options](#options) arguments.

```
