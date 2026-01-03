---
doc_id: ops/moonrepo/vcs-hooks
chunk_id: ops/moonrepo/vcs-hooks#chunk-1
heading_path: ["VCS hooks"]
chunk_type: prose
tokens: 247
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>VCS hooks</title>
  <description>VCS hooks (most popular with [Git](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)) are a mechanism for running scripts at pre-defined phases in the VCS&apos;s lifecycle, most commonly pre-commit</description>
  <created_at>2026-01-02T19:55:27.203095</created_at>
  <updated_at>2026-01-02T19:55:27.203095</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Defining hooks" level="2"/>
    <section name="Accessing arguments (v1.40.3)" level="3"/>
    <section name="Enabling hooks" level="2"/>
    <section name="Automatically for everyone" level="3"/>
    <section name="Manually by each developer" level="3"/>
    <section name="Disabling hooks" level="2"/>
    <section name="How it works" level="2"/>
    <section name="Git" level="3"/>
    <section name="Examples" level="2"/>
    <section name="Pre-commit" level="3"/>
  </sections>
  <features>
    <feature>accessing_arguments_v1403</feature>
    <feature>automatically_for_everyone</feature>
    <feature>defining_hooks</feature>
    <feature>disabling_hooks</feature>
    <feature>enabling_hooks</feature>
    <feature>examples</feature>
    <feature>how_it_works</feature>
    <feature>manually_by_each_developer</feature>
    <feature>pre-commit</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/commands/sync/hooks</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>vcs,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# VCS hooks

> **Context**: VCS hooks (most popular with [Git](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)) are a mechanism for running scripts at pre-defined phase

v1.9.0

VCS hooks (most popular with [Git](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)) are a mechanism for running scripts at pre-defined phases in the VCS's lifecycle, most commonly pre-commit, pre-push, or pre-merge. With moon, we provide a built-in solution for managing hooks, and syncing them across developers and machines.

- [Learn more about Git hooks](https://git-scm.com/docs/githooks)
