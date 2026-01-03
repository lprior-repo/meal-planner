---
doc_id: ops/moonrepo/typescript
chunk_id: ops/moonrepo/typescript#chunk-1
heading_path: ["TypeScript example"]
chunk_type: prose
tokens: 221
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>TypeScript example</title>
  <description>In this guide, you&apos;ll learn how to integrate [TypeScript](https://www.typescriptlang.org/) into moon. We&apos;ll be using [project references](/docs/guides/javascript/typescript-project-refs), as it ensure</description>
  <created_at>2026-01-02T19:55:27.116779</created_at>
  <updated_at>2026-01-02T19:55:27.116779</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Setup" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Sharing" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to preserve pretty output?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_preserve_pretty_output</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>sharing</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/javascript/typescript-project-refs</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>advanced,operations,javascript,typescript,moonrepo</tags>
</doc_metadata>
-->

# TypeScript example

> **Context**: In this guide, you'll learn how to integrate [TypeScript](https://www.typescriptlang.org/) into moon. We'll be using [project references](/docs/guides

In this guide, you'll learn how to integrate [TypeScript](https://www.typescriptlang.org/) into moon. We'll be using [project references](/docs/guides/javascript/typescript-project-refs), as it ensures that only affected projects are built, and not the entire repository.

Begin by installing `typescript` and any pre-configured tsconfig packages in your root. We suggest using the same version across the entire repository.

```
yarn add --dev typescript tsconfig-moon
```
