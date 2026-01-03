---
doc_id: ops/moonrepo/storybook
chunk_id: ops/moonrepo/storybook#chunk-1
heading_path: ["Storybook example"]
chunk_type: prose
tokens: 288
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Storybook example</title>
  <description>Storybook is a frontend workshop for building UI components and pages in isolation. Thousands of teams use it for UI development, testing, and documentation. It&apos;s open source and free.</description>
  <created_at>2026-01-02T19:55:27.108718</created_at>
  <updated_at>2026-01-02T19:55:27.108718</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Setup" level="2"/>
    <section name="Vite integration" level="3"/>
    <section name="Webpack integration" level="3"/>
    <section name="Jest integration" level="3"/>
    <section name="Configuration" level="2"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>jest_integration</feature>
    <feature>setup</feature>
    <feature>vite_integration</feature>
    <feature>webpack_integration</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/jest</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>advanced,storybook,operations,moonrepo</tags>
</doc_metadata>
-->

# Storybook example

> **Context**: Storybook is a frontend workshop for building UI components and pages in isolation. Thousands of teams use it for UI development, testing, and documen

Storybook is a frontend workshop for building UI components and pages in isolation. Thousands of teams use it for UI development, testing, and documentation. It's open source and free.

[Storybook v7](https://storybook.js.org/docs/7.0) is typically coupled with [Vite](https://vitejs.dev/). To scaffold a new Storybook project with Vite, run the following command in a project root. This guide assumes you are using React, however it is possible to use almost any (meta) framework with Storybook.

```
cd <project> && npx storybook init
```

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite) and [using Jest with moon](/docs/guides/examples/jest) for a more holistic view.
