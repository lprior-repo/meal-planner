---
doc_id: ops/moonrepo/toolchain
chunk_id: ops/moonrepo/toolchain#chunk-1
heading_path: ["Toolchain"]
chunk_type: prose
tokens: 234
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>.moon/toolchain.{pkl,yml}</title>
  <description>The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.</description>
  <created_at>2026-01-02T19:55:27.013639</created_at>
  <updated_at>2026-01-02T19:55:27.013639</updated_at>
  <language>en</language>
  <sections count="32">
    <section name="`extends`" level="2"/>
    <section name="`moon` (v1.29.0)" level="2"/>
    <section name="`manifestUrl`" level="3"/>
    <section name="`downloadUrl`" level="3"/>
    <section name="`proto` (v1.39.0)" level="2"/>
    <section name="`version`" level="3"/>
    <section name="JavaScript" level="2"/>
    <section name="`node`" level="3"/>
    <section name="`version`" level="4"/>
    <section name="`packageManager`" level="4"/>
  </sections>
  <features>
    <feature>addmsrvconstraint_v1370</feature>
    <feature>createmissingconfig</feature>
    <feature>downloadurl</feature>
    <feature>extends</feature>
    <feature>javascript</feature>
    <feature>manifesturl</feature>
    <feature>moon_v1290</feature>
    <feature>node</feature>
    <feature>npm_pnpm_yarn_bun</feature>
    <feature>packagemanager</feature>
    <feature>packagemanager_v1320</feature>
    <feature>proto_v1390</feature>
    <feature>python</feature>
    <feature>python_v1300</feature>
    <feature>rust</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/pkl-config</entity>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
    <entity relationship="uses">/docs/proto/config</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
  </related_entities>
  <examples count="18">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>moontoolchainpklyml,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# .moon/toolchain.{pkl,yml}

> **Context**: The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

Managing tool version's within the toolchain ensures a deterministic environment across any machine (whether a developer, CI, or production machine).

.moon/toolchain.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/toolchain.json'
```

> Toolchain configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
