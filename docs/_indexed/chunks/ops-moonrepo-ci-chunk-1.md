---
doc_id: ops/moonrepo/ci
chunk_id: ops/moonrepo/ci#chunk-1
heading_path: ["ci"]
chunk_type: prose
tokens: 284
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Continuous integration (CI)</title>
  <description>All companies and projects rely on continuous integration (CI) to ensure high quality code and to avoid regressions. Because this is such a critical piece of every developer&apos;s workflow, we wanted to s</description>
  <created_at>2026-01-02T19:55:27.049532</created_at>
  <updated_at>2026-01-02T19:55:27.049532</updated_at>
  <language>en</language>
  <sections count="18">
    <section name="How it works" level="2"/>
    <section name="Configuring tasks" level="2"/>
    <section name="Integrating" level="2"/>
    <section name="GitHub" level="3"/>
    <section name="Buildkite" level="3"/>
    <section name="CircleCI" level="3"/>
    <section name="TravisCI" level="3"/>
    <section name="Choosing targets (v1.14.0)" level="2"/>
    <section name="Comparing revisions" level="2"/>
    <section name="Parallelizing tasks" level="2"/>
  </sections>
  <features>
    <feature>buildkite</feature>
    <feature>caching_artifacts</feature>
    <feature>choosing_targets_v1140</feature>
    <feature>circleci</feature>
    <feature>community_offerings</feature>
    <feature>comparing_revisions</feature>
    <feature>configuring_tasks</feature>
    <feature>github</feature>
    <feature>github_actions</feature>
    <feature>how_it_works</feature>
    <feature>integrating</feature>
    <feature>manual_persistence</feature>
    <feature>parallelizing_tasks</feature>
    <feature>reporting_run_results</feature>
    <feature>travisci</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/commands/ci</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/guides/remote-cache</entity>
  </related_entities>
  <examples count="12">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>continuous,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Continuous integration (CI)

> **Context**: All companies and projects rely on continuous integration (CI) to ensure high quality code and to avoid regressions. Because this is such a critical p

All companies and projects rely on continuous integration (CI) to ensure high quality code and to avoid regressions. Because this is such a critical piece of every developer's workflow, we wanted to support it as a first-class feature within moon, and we do just that with the [`moon ci`](/docs/commands/ci) command.
