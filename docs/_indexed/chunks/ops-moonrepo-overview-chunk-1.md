---
doc_id: ops/moonrepo/overview
chunk_id: ops/moonrepo/overview#chunk-1
heading_path: ["Overview"]
chunk_type: prose
tokens: 286
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Overview</title>
  <description>The following options are available for *all* moon commands.</description>
  <created_at>2026-01-02T19:55:26.921632</created_at>
  <updated_at>2026-01-02T19:55:26.921632</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Caching" level="2"/>
    <section name="Colors" level="2"/>
    <section name="Themes (v1.35.0)" level="3"/>
    <section name="Piped output" level="3"/>
    <section name="Concurrency" level="2"/>
    <section name="Debugging" level="2"/>
    <section name="Logging" level="2"/>
    <section name="Writing logs to a file" level="3"/>
    <section name="Profiling (v1.26.0)" level="2"/>
  </sections>
  <features>
    <feature>caching</feature>
    <feature>colors</feature>
    <feature>concurrency</feature>
    <feature>debugging</feature>
    <feature>logging</feature>
    <feature>piped_output</feature>
    <feature>profiling_v1260</feature>
    <feature>themes_v1350</feature>
    <feature>writing_logs_to_a_file</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/cache</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>overview,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Overview

> **Context**: The following options are available for *all* moon commands.

The following options are available for *all* moon commands.

-   `--cache <mode>` - The mode for [cache operations](#caching).
-   `--color` - Force [colored output](#colors) for moon (not tasks).
-   `--concurrency`, `-c` - Maximum number of threads to utilize.
-   `--dump` - Dump a [trace profile](#profiling) to the working directory.
-   `--help` - Display the help menu for the current command.
-   `--log <level>` - The lowest [log level to output](#logging).
-   `--logFile <file>` - Write logs to the defined file.
-   `--quiet`, `-q` - Hide all non-important moon specific terminal output.
-   `--theme` - Terminal theme to write output in. v1.35.0
-   `--version` - Display the version of the CLI.
