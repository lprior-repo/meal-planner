---
doc_id: ops/windmill/branch-specific-items
chunk_id: ops/windmill/branch-specific-items#chunk-1
heading_path: ["Branch-specific items"]
chunk_type: prose
tokens: 257
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Branch-specific items</title>
  <description>Branch-specific items allow you to have different versions of resources and variables per Git branch. This enables teams to maintain environment-specific configurations (dev/staging/prod) that automat</description>
  <created_at>2026-01-02T19:55:27.474765</created_at>
  <updated_at>2026-01-02T19:55:27.474765</updated_at>
  <language>en</language>
  <sections count="21">
    <section name="How branch-specific items work" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Branch-specific items" level="3"/>
    <section name="Common specific items" level="3"/>
    <section name="Pattern matching" level="3"/>
    <section name="Branch name safety" level="2"/>
    <section name="File path transformation" level="2"/>
    <section name="Transform logic" level="3"/>
    <section name="Resource files" level="3"/>
    <section name="Supported file types" level="3"/>
  </sections>
  <features>
    <feature>basic_setup</feature>
    <feature>best_practices</feature>
    <feature>branch-specific_items</feature>
    <feature>branch_name_safety</feature>
    <feature>common_specific_items</feature>
    <feature>configuration</feature>
    <feature>configuration_patterns</feature>
    <feature>file_path_transformation</feature>
    <feature>files_in_wrong_workspace</feature>
    <feature>git_sync_integration</feature>
    <feature>how_branch-specific_items_work</feature>
    <feature>pattern_matching</feature>
    <feature>related_documentation</feature>
    <feature>resource_files</feature>
    <feature>supported_file_types</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-2</dependency>
    <dependency type="feature">ops/windmill/sync</dependency>
    <dependency type="feature">ops/windmill/gitsync-settings</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../11_git_sync/index.mdx</entity>
    <entity relationship="uses">./sync.mdx</entity>
    <entity relationship="uses">./gitsync-settings.mdx</entity>
    <entity relationship="uses">../11_git_sync/index.mdx</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,branchspecific,advanced,operations</tags>
</doc_metadata>
-->

# Branch-specific items

> **Context**: Branch-specific items allow you to have different versions of resources and variables per Git branch. This enables teams to maintain environment-speci

Branch-specific items allow you to have different versions of resources and variables per Git branch. This enables teams to maintain environment-specific configurations (dev/staging/prod) that automatically sync to the correct branch-namespaced files locally while maintaining clean base paths in the Windmill workspace.
