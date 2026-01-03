---
doc_id: tutorial/moonrepo/angular
chunk_id: tutorial/moonrepo/angular#chunk-1
heading_path: ["Angular example"]
chunk_type: prose
tokens: 197
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Angular example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Angular](https://angular.io/) into moon.</description>
  <created_at>2026-01-02T19:55:27.084232</created_at>
  <updated_at>2026-01-02T19:55:27.084232</updated_at>
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
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>tutorial,beginner,angular,moonrepo</tags>
</doc_metadata>
-->

# Angular example

> **Context**: In this guide, you'll learn how to integrate [Angular](https://angular.io/) into moon.

In this guide, you'll learn how to integrate [Angular](https://angular.io/) into moon.

Begin by creating a new Angular project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx -p @angular/cli@latest ng new angular-app
```

> View the [official Angular docs](https://angular.io/start) for a more in-depth guide to getting started!
