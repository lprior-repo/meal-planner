---
doc_id: tutorial/moonrepo/nuxt
chunk_id: tutorial/moonrepo/nuxt#chunk-1
heading_path: ["Nuxt example"]
chunk_type: prose
tokens: 217
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>build-tools</category>
  <title>Nuxt example</title>
  <description>In this guide, you&apos;ll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.</description>
  <created_at>2026-01-02T19:55:27.099708</created_at>
  <updated_at>2026-01-02T19:55:27.099708</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Testing" level="2"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>testing</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/guides/examples/vue</entity>
    <entity relationship="uses">/docs/guides/examples/jest</entity>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>tutorial,nuxt,beginner,moonrepo</tags>
</doc_metadata>
-->

# Nuxt example

> **Context**: In this guide, you'll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.

In this guide, you'll learn how to integrate [Nuxt v3](https://nuxt.com), a [Vue](/docs/guides/examples/vue) framework, into moon.

Begin by creating a new Nuxt project at a specified folder path (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx nuxi init <project>
```

> View the [official Nuxt docs](https://nuxt.com/docs/getting-started/installation) for a more in-depth guide to getting started!
