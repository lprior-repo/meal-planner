---
doc_id: ops/moonrepo/scaffold
chunk_id: ops/moonrepo/scaffold#chunk-1
heading_path: ["docker scaffold"]
chunk_type: prose
tokens: 204
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>docker scaffold</title>
  <description>The `moon docker scaffold &lt;...projects&gt;` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of Docker&apos;s layer caching. It utilizes the [project g</description>
  <created_at>2026-01-02T19:55:26.911024</created_at>
  <updated_at>2026-01-02T19:55:26.911024</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Configuration" level="3"/>
    <section name="How it works" level="2"/>
    <section name="Workspace" level="3"/>
    <section name="Sources" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>how_it_works</feature>
    <feature>sources</feature>
    <feature>workspace</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/docker</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>docker,operations,moonrepo</tags>
</doc_metadata>
-->

# docker scaffold

> **Context**: The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of 

The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of Docker's layer caching. It utilizes the [project graph](/docs/config/workspace#projects) to copy only critical files, like manifests, lockfiles, and configuration.

```
