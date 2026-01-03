---
id: ops/moonrepo/add
title: "toolchain add"
category: ops
tags: ["toolchain", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>toolchain add</title>
  <description>The `moon toolchain add &lt;id&gt; [plugin]` command will add a toolchain to the workspace by injecting a configuration block into `.moon/toolchain.yml`. To do this, the command will download the WASM plugi</description>
  <created_at>2026-01-02T19:55:26.946126</created_at>
  <updated_at>2026-01-02T19:55:26.946126</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/wasm-plugins</entity>
    <entity relationship="uses">/docs/guides/wasm-plugins</entity>
    <entity relationship="uses">/docs/guides/wasm-plugins</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>toolchain,operations,moonrepo</tags>
</doc_metadata>
-->

# toolchain add

> **Context**: The `moon toolchain add <id> [plugin]` command will add a toolchain to the workspace by injecting a configuration block into `.moon/toolchain.yml`. To

v1.38.0

The `moon toolchain add <id> [plugin]` command will add a toolchain to the workspace by injecting a configuration block into `.moon/toolchain.yml`. To do this, the command will download the WASM plugin, extract information, and call initialize functions.

For built-in toolchains, the [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) argument is optional, and will be derived from the identifier.

```
$ moon toolchain add typescript
```

For third-party toolchains, the [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) argument is required, and must point to the WASM plugin.

```
$ moon toolchain add custom https://example.com/path/to/plugin.wasm
```

## Arguments

- `<id>` - ID of the toolchain to use.
- `[plugin]` - Optional [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) for third-party toolchains.

### Options

- `--minimal` - Generate minimal configurations and sane defaults.
- `--yes` - Skip all prompts and enables tools based on file detection.


## See Also

- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
