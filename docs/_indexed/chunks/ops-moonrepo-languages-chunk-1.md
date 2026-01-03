---
doc_id: ops/moonrepo/languages
chunk_id: ops/moonrepo/languages#chunk-1
heading_path: ["Languages"]
chunk_type: prose
tokens: 254
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Languages</title>
  <description>Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management tool. To that end, we&apos;ve designed our languages to w</description>
  <created_at>2026-01-02T19:55:27.219189</created_at>
  <updated_at>2026-01-02T19:55:27.219189</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Enabling a language" level="2"/>
    <section name="System language and toolchain" level="2"/>
    <section name="Tier structure and responsibilities" level="2"/>
    <section name="Tier 0 = Unsupported" level="3"/>
    <section name="Tier 1 = Language" level="3"/>
    <section name="Tier 2 = Platform" level="3"/>
    <section name="Tier 3 = Toolchain" level="3"/>
  </sections>
  <features>
    <feature>enabling_a_language</feature>
    <feature>system_language_and_toolchain</feature>
    <feature>tier_0_unsupported</feature>
    <feature>tier_1_language</feature>
    <feature>tier_2_platform</feature>
    <feature>tier_3_toolchain</feature>
    <feature>tier_structure_and_responsibilities</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>advanced,operations,moonrepo,javascript,languages</tags>
</doc_metadata>
-->

# Languages

> **Context**: Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management to

Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management tool. To that end, we've designed our languages to work like plugins, where their functionality is implemented in isolation, and is *opt-in*.

> We do not support third-party language plugins at this time, but are working towards it!
