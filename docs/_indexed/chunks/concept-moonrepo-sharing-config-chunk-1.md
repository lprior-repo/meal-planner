---
doc_id: concept/moonrepo/sharing-config
chunk_id: concept/moonrepo/sharing-config#chunk-1
heading_path: ["Sharing workspace configuration"]
chunk_type: prose
tokens: 284
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Sharing workspace configuration</title>
  <description>For large companies, open source maintainers, and those that love reusability, more often than not you&apos;ll want to use the same configuration across all repositories for consistency. This helps reduce </description>
  <created_at>2026-01-02T19:55:27.201441</created_at>
  <updated_at>2026-01-02T19:55:27.201441</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Versioning" level="2"/>
    <section name="Using versioned filenames" level="3"/>
    <section name="Using branches, tags, or commits" level="3"/>
  </sections>
  <features>
    <feature>using_branches_tags_or_commits</feature>
    <feature>using_versioned_filenames</feature>
    <feature>versioning</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>sharing,concept,moonrepo</tags>
</doc_metadata>
-->

# Sharing workspace configuration

> **Context**: For large companies, open source maintainers, and those that love reusability, more often than not you'll want to use the same configuration across al

For large companies, open source maintainers, and those that love reusability, more often than not you'll want to use the same configuration across all repositories for consistency. This helps reduce the maintenance burden while ensuring a similar developer experience.

To help streamline this process, moon provides an `extends` setting in both [`.moon/workspace.yml`](/docs/config/workspace#extends), [`.moon/toolchain.yml`](/docs/config/toolchain#extends), and [`.moon/tasks.yml`](/docs/config/tasks#extends). This setting requires a HTTPS URL *or* relative file system path that points to a valid YAML document for the configuration in question.

A great way to share configuration is by using GitHub's "raw file view", as demonstrated below using our very own [examples repository](https://github.com/moonrepo/examples).

.moon/tasks.yml

```yaml
extends: 'https://raw.githubusercontent.com/moonrepo/examples/master/.moon/tasks.yml'
```
