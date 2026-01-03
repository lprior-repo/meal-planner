---
id: ops/moonrepo/ext
title: "ext"
category: ops
tags: ["ext", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>ext</title>
  <description>The `moon ext &lt;id&gt;` command will execute an extension (a WASM plugin) that has been configured with the [`extensions`](/docs/config/workspace#extensions) setting in [`.moon/workspace.yml`](/docs/confi</description>
  <created_at>2026-01-02T19:55:26.914470</created_at>
  <updated_at>2026-01-02T19:55:26.914470</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Arguments" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config</entity>
    <entity relationship="uses">/docs/guides/extensions</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>ext,operations,moonrepo</tags>
</doc_metadata>
-->

# ext

> **Context**: The `moon ext <id>` command will execute an extension (a WASM plugin) that has been configured with the [`extensions`](/docs/config/workspace#extensio

v1.20.0

The `moon ext <id>` command will execute an extension (a WASM plugin) that has been configured with the [`extensions`](/docs/config/workspace#extensions) setting in [`.moon/workspace.yml`](/docs/config). View our official [extensions guide](/docs/guides/extensions) for more information.

```
$ moon ext download -- --url https://github.com/moonrepo/moon/archive/refs/tags/v1.19.3.zip
```

Extensions typically support command line arguments, which *must* be passed after a `--` separator (as seen above). Any arguments before the separator will be passed to the `moon ext` command itself.

**Caution:** This command requires an internet connection if the extension's `.wasm` file must be downloaded from a URL, and it hasn't been cached locally.

## Arguments

-   `<id>` - Name of the extension to execute.
-   `[-- <args>]` - Arguments to pass to the extension.

### Configuration

-   [`extensions`](/docs/config/workspace#extensions) in `.moon/workspace.yml`


## See Also

- [`extensions`](/docs/config/workspace#extensions)
- [`.moon/workspace.yml`](/docs/config)
- [extensions guide](/docs/guides/extensions)
- [`extensions`](/docs/config/workspace#extensions)
