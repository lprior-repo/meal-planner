---
id: meta/general/readme
title: "Documentation"
category: meta
tags: ["meta", "documentation"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core</category>
  <title>Documentation</title>
  <description>**Designed for both human and AI consumption.** Each doc links to related docs, making it easy to navigate whether you&apos;re a person reading or an AI agent following the thread.</description>
  <created_at>2026-01-02T19:55:26.824443</created_at>
  <updated_at>2026-01-02T19:55:26.824443</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Essential Reads (5 min)" level="2"/>
    <section name="Setup (One-Time)" level="2"/>
    <section name="Features" level="2"/>
    <section name="For Developers" level="2"/>
    <section name="External References" level="2"/>
    <section name="Design for AI + Humans" level="2"/>
  </sections>
  <features>
    <feature>design_for_ai_humans</feature>
    <feature>essential_reads_5_min</feature>
    <feature>external_references</feature>
    <feature>features</feature>
    <feature>for_developers</feature>
    <feature>setup_one-time</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/general/architecture</dependency>
    <dependency type="feature">ops/general/moon-ci-pipeline</dependency>
    <dependency type="feature">tutorial/general/fatsecret-oauth-setup</dependency>
    <dependency type="feature">concept/general/recipe-import-pipeline</dependency>
    <dependency type="feature">concept/general/ai-documentation-system</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">ARCHITECTURE.md</entity>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
    <entity relationship="uses">FATSECRET_OAUTH_SETUP.md</entity>
    <entity relationship="uses">RECIPE_IMPORT_PIPELINE.md</entity>
    <entity relationship="uses">../AGENTS.md</entity>
    <entity relationship="uses">AI_DOCUMENTATION_SYSTEM.md</entity>
    <entity relationship="uses">../docs/fatsecret/</entity>
    <entity relationship="uses">../docs/tandoor/</entity>
    <entity relationship="uses">../docs/windmill/</entity>
    <entity relationship="uses">AI_DOCUMENTATION_SYSTEM.md</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>meta,documentation</tags>
</doc_metadata>
-->

# Documentation

> **Context**: **Designed for both human and AI consumption.** Each doc links to related docs, making it easy to navigate whether you're a person reading or an AI ag

**Designed for both human and AI consumption.** Each doc links to related docs, making it easy to navigate whether you're a person reading or an AI agent following the thread.

## Essential Reads (5 min)

**New to the project?** Start here:

1. [ARCHITECTURE.md](./ops-general-architecture.md) - How code is organized (domain-based, binaries, flows)
2. [MOON_CI_PIPELINE.md](./ops-general-moon-ci-pipeline.md) - How to build and test locally

## Setup (One-Time)

3. [FATSECRET_OAUTH_SETUP.md](./tutorial-general-fatsecret-oauth-setup.md) - Connect FatSecret account (5-10 min)

## Features

- [RECIPE_IMPORT_PIPELINE.md](./concept-general-recipe-import-pipeline.md) - Auto-import recipes from URLs

## For Developers

- [../AGENTS.md](../AGENTS.md) - AI agent workflow (issue tracking, credentials, deployment)
- [AI_DOCUMENTATION_SYSTEM.md](./concept-general-ai-documentation-system.md) - Documentation design for AI and humans

## External References

- [../docs/fatsecret/](../docs/fatsecret/) - FatSecret API reference (auto-generated)
- [../docs/tandoor/](../docs/tandoor/) - Tandoor API reference (auto-generated)
- [../docs/windmill/](../docs/windmill/) - Windmill reference (official docs)

## Design for AI + Humans

Each doc:
- **Answers one question clearly**
- **Links to 2-3 related docs** (so you never get stuck)
- **Uses headings, tables, code** (scannable for humans, structured for AI)
- **Stays under 1500 words** (focused, no walls of text)
- **Points to next steps** (clear navigation)

See: [AI_DOCUMENTATION_SYSTEM.md](./concept-general-ai-documentation-system.md) for how this works


## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md)
- [FATSECRET_OAUTH_SETUP.md](FATSECRET_OAUTH_SETUP.md)
- [RECIPE_IMPORT_PIPELINE.md](RECIPE_IMPORT_PIPELINE.md)
- [../AGENTS.md](../AGENTS.md)
