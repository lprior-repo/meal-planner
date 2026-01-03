---
doc_id: tutorial/moonrepo/remix
chunk_id: tutorial/moonrepo/remix#chunk-1
heading_path: ["Remix example"]
chunk_type: prose
tokens: 240
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Remix example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Remix](https://remix.run) into moon.</description>
  <created_at>2026-01-02T19:55:27.105370</created_at>
  <updated_at>2026-01-02T19:55:27.105370</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>tutorial,beginner,remix,moonrepo</tags>
</doc_metadata>
-->

# Remix example

> **Context**: In this guide, you'll learn how to integrate [Remix](https://remix.run) into moon.

In this guide, you'll learn how to integrate [Remix](https://remix.run) into moon.

Begin by creating a new Remix project at a specified folder path (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx create-remix
```

During this installation, Remix will ask a handful of questions, but be sure to answer "No" for the "Do you want me to run `npm install`?" question. We suggest installing dependencies at the workspace root via package workspaces!

> View the [official Remix docs](https://remix.run/docs/en/v1) for a more in-depth guide to getting started!
