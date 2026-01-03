---
doc_id: ops/moonrepo/pkl-config
chunk_id: ops/moonrepo/pkl-config#chunk-1
heading_path: ["Pkl configuration"]
chunk_type: prose
tokens: 375
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Pkl configuration</title>
  <description>While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you haven&apos;t heard of Pkl yet, [Pkl is a programmable confi</description>
  <created_at>2026-01-02T19:55:27.183571</created_at>
  <updated_at>2026-01-02T19:55:27.183571</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Installing Pkl" level="2"/>
    <section name="Using Pkl" level="2"/>
    <section name="Caveats and restrictions" level="3"/>
    <section name="Example configs" level="2"/>
    <section name="`.moon/workspace.pkl`" level="3"/>
    <section name="`.moon/toolchain.pkl`" level="3"/>
    <section name="`moon.pkl`" level="3"/>
    <section name="Example functionality" level="2"/>
    <section name="Loops and conditionals" level="3"/>
    <section name="Local variables" level="3"/>
  </sections>
  <features>
    <feature>caveats_and_restrictions</feature>
    <feature>example_configs</feature>
    <feature>example_functionality</feature>
    <feature>installing_pkl</feature>
    <feature>local_variables</feature>
    <feature>loops_and_conditionals</feature>
    <feature>moonpkl</feature>
    <feature>moontoolchainpkl</feature>
    <feature>moonworkspacepkl</feature>
    <feature>using_pkl</feature>
  </features>
  <dependencies>
    <dependency type="crate">serde</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>pkl,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Pkl configuration

> **Context**: While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you have

v1.32.0

While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you haven't heard of Pkl yet, [Pkl is a programmable configuration format by Apple](https://pkl-lang.org/). We like Pkl, as it meets the following requirements:

- Is easy to read and write.
- Is dynamic and programmable (loops, variables, etc).
- Has type-safety / built-in schema support.
- Has Rust serde integration.

The primary requirement that we are hoping to achieve is supporting a configuration format that is *programmable*. We want something that has native support for variables, loops, conditions, and more, so that you could curate and compose your configuration very easily. Hacking this functionality into YAML is a terrible user experience in our opinion!
