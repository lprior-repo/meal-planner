---
doc_id: tutorial/moonrepo/nest
chunk_id: tutorial/moonrepo/nest#chunk-1
heading_path: ["Nest example"]
chunk_type: prose
tokens: 180
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Nest example</title>
  <description>In this guide, you&apos;ll learn how to integrate [NestJS](https://nestjs.com/) into moon.</description>
  <created_at>2026-01-02T19:55:27.095717</created_at>
  <updated_at>2026-01-02T19:55:27.095717</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tutorial,beginner,nest,moonrepo</tags>
</doc_metadata>
-->

# Nest example

> **Context**: In this guide, you'll learn how to integrate [NestJS](https://nestjs.com/) into moon.

In this guide, you'll learn how to integrate [NestJS](https://nestjs.com/) into moon.

Begin by creating a new NestJS project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
npx @nestjs/cli@latest new nestjs-app --skip-git
```

> View the [official NestJS docs](https://docs.nestjs.com/first-steps) for a more in-depth guide to getting started!
