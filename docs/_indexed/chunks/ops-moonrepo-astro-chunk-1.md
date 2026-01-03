---
doc_id: ops/moonrepo/astro
chunk_id: ops/moonrepo/astro#chunk-1
heading_path: ["Astro example"]
chunk_type: prose
tokens: 174
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Astro example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Astro](https://docs.astro.build).</description>
  <created_at>2026-01-02T19:55:27.087319</created_at>
  <updated_at>2026-01-02T19:55:27.087319</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="Prettier integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>prettier_integration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/prettier</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>astro,operations,moonrepo</tags>
</doc_metadata>
-->

# Astro example

> **Context**: In this guide, you'll learn how to integrate [Astro](https://docs.astro.build).

In this guide, you'll learn how to integrate [Astro](https://docs.astro.build).

Begin by creating a new Astro project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npm create astro@latest
```
