---
id: concept/moonrepo/deno-handbook
title: "Deno handbook"
category: concept
tags: ["deno", "typescript", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Deno handbook</title>
  <description>Utilizing Deno in a TypeScript based monorepo can be a non-trivial task. With this handbook, we&apos;ll help guide you through this process.</description>
  <created_at>2026-01-02T19:55:27.135765</created_at>
  <updated_at>2026-01-02T19:55:27.135765</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="moon setup" level="2"/>
    <section name="Enabling the language" level="3"/>
    <section name="Work in progress" level="3"/>
    <section name="Coming soon!" level="2"/>
  </sections>
  <features>
    <feature>coming_soon</feature>
    <feature>enabling_the_language</feature>
    <feature>moon_setup</feature>
    <feature>work_in_progress</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/moon</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>deno,typescript,concept,moonrepo</tags>
</doc_metadata>
-->

# Deno handbook

> **Context**: Utilizing Deno in a TypeScript based monorepo can be a non-trivial task. With this handbook, we'll help guide you through this process.

Utilizing Deno in a TypeScript based monorepo can be a non-trivial task. With this handbook, we'll help guide you through this process.

info

This guide is a living document and will continue to be updated over time!

## moon setup

For this part of the handbook, we'll be focusing on [moon](/moon), our task runner. To start, languages in moon act like plugins, where their functionality and support *is not* enabled unless explicitly configured. We follow this approach to avoid unnecessary overhead.

### Enabling the language

To enable TypeScript support via Deno, define the [`deno`](/docs/config/toolchain#deno) setting in [`.moon/toolchain.yml`](/docs/config/toolchain), even if an empty object.

.moon/toolchain.yml

```
## Enable Deno
deno: {}

## Enable Deno and override default settings
deno:
  lockfile: true
```

Or by pinning a `deno` version in [`.prototools`](/docs/proto/config) in the workspace root.

.prototools

```
deno = "1.31.0"
```

This will enable the Deno toolchain and provide the following automations around its ecosystem:

- Automatic handling and caching of lockfiles (when the setting is enabled).
- Relationships between projects will automatically be discovered based on `imports`, `importMap`, and `deps.ts` (currently experimental).
- And more to come!

### Work in progress

caution

Deno support is currently experimental while we finalize the implementation.

The following features are not supported:

- `deno.jsonc` files (use `deno.json` instead).
- `files.exclude` are currently considered an input. These will be filtered in a future release.

## Coming soon!

The handbook is currently being written while we finalize our Deno integration support!


## See Also

- [moon](/moon)
- [`deno`](/docs/config/toolchain#deno)
- [`.moon/toolchain.yml`](/docs/config/toolchain)
- [`.prototools`](/docs/proto/config)
