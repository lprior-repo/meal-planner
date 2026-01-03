---
doc_id: ops/moonrepo/vite
chunk_id: ops/moonrepo/vite#chunk-1
heading_path: ["Vite & Vitest example"]
chunk_type: code
tokens: 205
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Vite &amp; Vitest example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.</description>
  <created_at>2026-01-02T19:55:27.121086</created_at>
  <updated_at>2026-01-02T19:55:27.121086</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Setup" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>vite,operations,moonrepo</tags>
</doc_metadata>
-->

# Vite & Vitest example

> **Context**: In this guide, you'll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.

In this guide, you'll learn how to integrate [Vite](https://vitejs.dev/) and [Vitest](https://vitest.dev/) into moon.

Begin by creating a new Vite project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
yarn create vite
```

If you plan on using Vitest, run the following command to add the `vitest` dependency to a project, otherwise skip to the setup section.

```
yarn workspace <project> add --dev vitest
```
