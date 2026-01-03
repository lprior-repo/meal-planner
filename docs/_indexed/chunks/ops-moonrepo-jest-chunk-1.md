---
doc_id: ops/moonrepo/jest
chunk_id: ops/moonrepo/jest#chunk-1
heading_path: ["Jest example"]
chunk_type: prose
tokens: 179
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Jest example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Jest](https://jestjs.io/) into moon.</description>
  <created_at>2026-01-02T19:55:27.093626</created_at>
  <updated_at>2026-01-02T19:55:27.093626</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Setup" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Sharing" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to test a single file or folder?" level="3"/>
    <section name="How to use `projects`?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_test_a_single_file_or_folder</feature>
    <feature>how_to_use_projects</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>sharing</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>jest,operations,moonrepo</tags>
</doc_metadata>
-->

# Jest example

> **Context**: In this guide, you'll learn how to integrate [Jest](https://jestjs.io/) into moon.

In this guide, you'll learn how to integrate [Jest](https://jestjs.io/) into moon.

Begin by installing `jest` in your root. We suggest using the same version across the entire repository.

```
yarn add --dev jest
```
