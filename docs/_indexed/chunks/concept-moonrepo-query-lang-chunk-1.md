---
doc_id: concept/moonrepo/query-lang
chunk_id: concept/moonrepo/query-lang#chunk-1
heading_path: ["Query language"]
chunk_type: prose
tokens: 262
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Query language</title>
  <description>moon supports an integrated query language, known as MQL, that can be used to filter and select projects from the project graph, using an SQL-like syntax. MQL is primarily used by [`moon run`](/docs/c</description>
  <created_at>2026-01-02T19:55:26.966546</created_at>
  <updated_at>2026-01-02T19:55:26.966546</updated_at>
  <language>en</language>
  <sections count="19">
    <section name="Syntax" level="2"/>
    <section name="Comparisons" level="3"/>
    <section name="Equals, Not equals" level="4"/>
    <section name="Like, Not like" level="4"/>
    <section name="Conditions" level="3"/>
    <section name="Grouping" level="3"/>
    <section name="Fields" level="2"/>
    <section name="`language`" level="3"/>
    <section name="`project`" level="3"/>
    <section name="`projectAlias`" level="3"/>
  </sections>
  <features>
    <feature>comparisons</feature>
    <feature>conditions</feature>
    <feature>equals_not_equals</feature>
    <feature>fields</feature>
    <feature>grouping</feature>
    <feature>language</feature>
    <feature>like_not_like</feature>
    <feature>project</feature>
    <feature>projectalias</feature>
    <feature>projectlayer_v1390</feature>
    <feature>projectname</feature>
    <feature>projectsource</feature>
    <feature>projectstack_v1220</feature>
    <feature>projecttype</feature>
    <feature>syntax</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/file-pattern</entity>
    <entity relationship="uses">/docs/concepts/token</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="18">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>sql,query,concept,moonrepo</tags>
</doc_metadata>
-->

# Query language

> **Context**: moon supports an integrated query language, known as MQL, that can be used to filter and select projects from the project graph, using an SQL-like syn

moon supports an integrated query language, known as MQL, that can be used to filter and select projects from the project graph, using an SQL-like syntax. MQL is primarily used by [`moon run`](/docs/commands/run) with the `--query` option.
