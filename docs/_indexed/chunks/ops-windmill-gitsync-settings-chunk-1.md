---
doc_id: ops/windmill/gitsync-settings
chunk_id: ops/windmill/gitsync-settings#chunk-1
heading_path: ["Git sync settings"]
chunk_type: prose
tokens: 358
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Git sync settings</title>
  <description>Managing git-sync configuration between your local `wmill.yaml` file and the Windmill workspace backend is made easy using the wmill CLI. Git-sync settings operations are behind the `wmill gitsync-set</description>
  <created_at>2026-01-02T19:55:27.484358</created_at>
  <updated_at>2026-01-02T19:55:27.484358</updated_at>
  <language>en</language>
  <sections count="13">
    <section name="Pull API" level="2"/>
    <section name="Options" level="3"/>
    <section name="Push API" level="2"/>
    <section name="Options" level="3"/>
    <section name="Configuration management" level="2"/>
    <section name="Settings managed" level="3"/>
    <section name="Configuration modes" level="3"/>
    <section name="Usage examples" level="2"/>
    <section name="Basic operations" level="3"/>
    <section name="Preview changes" level="3"/>
  </sections>
  <features>
    <feature>basic_operations</feature>
    <feature>branch-specific_operations</feature>
    <feature>configuration_management</feature>
    <feature>configuration_modes</feature>
    <feature>differences_from_sync_command</feature>
    <feature>options</feature>
    <feature>preview_changes</feature>
    <feature>pull_api</feature>
    <feature>push_api</feature>
    <feature>settings_managed</feature>
    <feature>usage_examples</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">ops/windmill/sync</dependency>
    <dependency type="feature">meta/windmill/index-2</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./sync.mdx</entity>
    <entity relationship="uses">../11_git_sync/index.mdx</entity>
    <entity relationship="uses">./sync.mdx</entity>
  </related_entities>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,advanced,operations,git</tags>
</doc_metadata>
-->

# Git sync settings

> **Context**: Managing git-sync configuration between your local `wmill.yaml` file and the Windmill workspace backend is made easy using the wmill CLI. Git-sync set

Managing git-sync configuration between your local `wmill.yaml` file and the Windmill workspace backend is made easy using the wmill CLI. Git-sync settings operations are behind the `wmill gitsync-settings` subcommand.

The `gitsync-settings` command allows you to synchronize filter settings, path configurations, and branch-specific overrides without affecting the actual workspace content (scripts, flows, apps, etc.).

Git-sync settings management is done using `wmill gitsync-settings pull` & `wmill gitsync-settings push`.

Settings operations are configuration-only and work with your `wmill.yaml` file structure. The command will show you the list of changes and ask for confirmation before applying them.

When pulling, the source is the remote workspace git-sync configuration and the target is your local `wmill.yaml` file, and when pushing, the source is your local `wmill.yaml` and the target is the remote workspace configuration.
