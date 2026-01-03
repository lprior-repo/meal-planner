---
doc_id: ops/moonrepo/eslint
chunk_id: ops/moonrepo/eslint#chunk-1
heading_path: ["ESLint example"]
chunk_type: prose
tokens: 191
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>ESLint example</title>
  <description>In this guide, you&apos;ll learn how to integrate [ESLint](https://eslint.org/) into moon.</description>
  <created_at>2026-01-02T19:55:27.090026</created_at>
  <updated_at>2026-01-02T19:55:27.090026</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Sharing" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to lint a single file or folder?" level="3"/>
    <section name="Should we use `overrides`?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_lint_a_single_file_or_folder</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>sharing</feature>
    <feature>should_we_use_overrides</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>eslint,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# ESLint example

> **Context**: In this guide, you'll learn how to integrate [ESLint](https://eslint.org/) into moon.

In this guide, you'll learn how to integrate [ESLint](https://eslint.org/) into moon.

Begin by installing `eslint` and any plugins in your root. We suggest using the same version across the entire repository.

```
yarn add --dev eslint eslint-config-moon
```
