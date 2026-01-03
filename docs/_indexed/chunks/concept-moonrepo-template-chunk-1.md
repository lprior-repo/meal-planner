---
doc_id: concept/moonrepo/template
chunk_id: concept/moonrepo/template#chunk-1
heading_path: ["template.{pkl,yml}"]
chunk_type: prose
tokens: 252
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>template.{pkl,yml}</title>
  <description>The `template.yml` file configures metadata and variables for a template, [used by the generator](/docs/guides/codegen), and must exist at the root of a named template folder.</description>
  <created_at>2026-01-02T19:55:27.006976</created_at>
  <updated_at>2026-01-02T19:55:27.006976</updated_at>
  <language>en</language>
  <sections count="25">
    <section name="`id` (v1.23.0)" level="2"/>
    <section name="`title` (Required)" level="2"/>
    <section name="`description` (Required)" level="2"/>
    <section name="`destination` (v1.19.0)" level="2"/>
    <section name="`extends` (v1.19.0)" level="2"/>
    <section name="`variables`" level="2"/>
    <section name="`type` (Required)" level="3"/>
    <section name="`internal` (v1.23.0)" level="3"/>
    <section name="`order` (v1.23.0)" level="3"/>
    <section name="Primitives &amp; collections" level="3"/>
  </sections>
  <features>
    <feature>array</feature>
    <feature>boolean</feature>
    <feature>default_required</feature>
    <feature>description_required</feature>
    <feature>destination_v1190</feature>
    <feature>enums</feature>
    <feature>extends_v1190</feature>
    <feature>force</feature>
    <feature>frontmatter</feature>
    <feature>id_v1230</feature>
    <feature>internal_v1230</feature>
    <feature>multiple</feature>
    <feature>number</feature>
    <feature>object</feature>
    <feature>order_v1230</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/codegen</entity>
    <entity relationship="uses">/docs/guides/pkl-config</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/guides/codegen</entity>
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="17">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>advanced,templatepklyml,concept,moonrepo</tags>
</doc_metadata>
-->

# template.{pkl,yml}

> **Context**: The `template.yml` file configures metadata and variables for a template, [used by the generator](/docs/guides/codegen), and must exist at the root of

The `template.yml` file configures metadata and variables for a template, [used by the generator](/docs/guides/codegen), and must exist at the root of a named template folder.

template.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/template.json'
```

> Template configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
