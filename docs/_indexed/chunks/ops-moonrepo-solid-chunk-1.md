---
doc_id: ops/moonrepo/solid
chunk_id: ops/moonrepo/solid#chunk-1
heading_path: ["Solid example"]
chunk_type: prose
tokens: 228
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Solid example</title>
  <description>[Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid is an application or library concern, and not a bui</description>
  <created_at>2026-01-02T19:55:27.107413</created_at>
  <updated_at>2026-01-02T19:55:27.107413</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Vite integration" level="3"/>
  </sections>
  <features>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
    <feature>vite_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/tags/solid</entity>
    <entity relationship="uses">/docs/tags/solidjs</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>javascript,solid,operations,moonrepo</tags>
</doc_metadata>
-->

# Solid example

> **Context**: [Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid i

[Solid](https://www.solidjs.com) (also known as SolidJS) is a JavaScript framework for building interactive web applications. Because of this, Solid is an application or library concern, and not a build system one, since the bundling of Solid is abstracted away through the application or a bundler.

With that being said, we do have some suggestions on utilizing Solid effectively in a monorepo. To begin, install Solid to a project.

```
yarn workspace <project> add solid-js
```
