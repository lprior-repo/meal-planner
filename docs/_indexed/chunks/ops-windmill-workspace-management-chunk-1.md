---
doc_id: ops/windmill/workspace-management
chunk_id: ops/windmill/workspace-management#chunk-1
heading_path: ["Workspace management"]
chunk_type: prose
tokens: 292
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Workspace management</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;cli&lt;/category&gt; &lt;title&gt;Windmill CLI Workspace Management&lt;/title&gt; &lt;description&gt;Manage workspaces via CLI&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:0</description>
  <created_at>2026-01-02T19:55:27.514201</created_at>
  <updated_at>2026-01-02T19:55:27.514201</updated_at>
  <language>en</language>
  <sections count="16">
    <section name="List workspaces" level="2"/>
    <section name="Adding a workspace" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Examples" level="3"/>
    <section name="Switch workspaces" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Examples" level="3"/>
    <section name="Selected workspace" level="2"/>
    <section name="Removing a workspace" level="2"/>
  </sections>
  <features>
    <feature>adding_a_workspace</feature>
    <feature>arguments</feature>
    <feature>encryption_key_during_instance_sync</feature>
    <feature>encryption_key_during_workspace_sync</feature>
    <feature>examples</feature>
    <feature>list_workspaces</feature>
    <feature>managing_encryption_keys</feature>
    <feature>options</feature>
    <feature>removing_a_workspace</feature>
    <feature>selected_workspace</feature>
    <feature>switch_workspaces</feature>
    <feature>whoami</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-46</dependency>
    <dependency type="feature">meta/windmill/index-47</dependency>
    <dependency type="feature">ops/windmill/sync</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">./cli_help.png.webp</entity>
    <entity relationship="uses">../../core_concepts/2_variables_and_secrets/index.mdx</entity>
    <entity relationship="uses">../../core_concepts/30_workspace_secret_encryption/index.mdx</entity>
    <entity relationship="uses">./sync.mdx</entity>
    <entity relationship="uses">./sync.mdx</entity>
  </related_entities>
  <examples count="10">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,workspace,advanced,operations</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Workspace Management</title>
  <description>Manage workspaces via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Workspace management" level="1"/>
    <section name="List workspaces" level="2"/>
    <section name="Adding a workspace" level="2"/>
    <section name="Switch workspaces" level="2"/>
    <section name="Removing a workspace" level="2"/>
    <section name="Selected workspace" level="2"/>
    <section name="Managing encryption keys" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>workspace_management</feature>
    <feature>multi_workspace_support</feature>
    <feature>encryption</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="4">
    <example>Add new workspace with prompts</example>
    <example>Switch between workspaces</example>
    <example>Remove workspace from CLI</example>
    <example>Manage encryption keys during sync</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,cli,wmill,workspace,add,switch,remove,encryption,sync</tags>
</doc_metadata>
-->

# Workspace management

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Workspace Management</title> <description>Manage workspaces vi

Windmill CLI can be used on several workspaces from several instances.
