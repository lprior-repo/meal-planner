---
id: ops/moonrepo/clean
title: "clean"
category: ops
tags: ["clean", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>clean</title>
  <description>The `moon clean` command will clean the current workspace by deleting stale cache. For the most part, the action pipeline will clean automatically, but this command can be used to reset the workspace </description>
  <created_at>2026-01-02T19:55:26.906481</created_at>
  <updated_at>2026-01-02T19:55:26.906481</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Options" level="3"/>
  </sections>
  <features>
    <feature>options</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>clean,operations,moonrepo</tags>
</doc_metadata>
-->

# clean

> **Context**: The `moon clean` command will clean the current workspace by deleting stale cache. For the most part, the action pipeline will clean automatically, bu

The `moon clean` command will clean the current workspace by deleting stale cache. For the most part, the action pipeline will clean automatically, but this command can be used to reset the workspace entirely.

```
$ moon clean

## Delete cache with a custom lifetime
$ moon clean --lifetime '24 hours'
```

### Options

-   `--lifetime` - The maximum lifetime of cached artifacts before being marked as stale. Defaults to "7 days".


## See Also

- [Documentation Index](./COMPASS.md)
