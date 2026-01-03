---
doc_id: concept/windmill/script
chunk_id: concept/windmill/script#chunk-1
heading_path: ["Scripts"]
chunk_type: prose
tokens: 293
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Scripts</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;cli&lt;/category&gt; &lt;title&gt;Windmill CLI Script Commands&lt;/title&gt; &lt;description&gt;Manage scripts via CLI&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:00Z&lt;/crea</description>
  <created_at>2026-01-02T19:55:27.495662</created_at>
  <updated_at>2026-01-02T19:55:27.495662</updated_at>
  <language>en</language>
  <sections count="18">
    <section name="Listing scripts" level="2"/>
    <section name="Pushing a script" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Examples" level="3"/>
    <section name="Creating a new script" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Examples" level="3"/>
    <section name="(Re-)Generating a script metadata file" level="2"/>
    <section name="package.json &amp; requirements.txt" level="3"/>
    <section name="Arguments" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>creating_a_new_script</feature>
    <feature>examples</feature>
    <feature>listing_scripts</feature>
    <feature>options</feature>
    <feature>packagejson_requirementstxt</feature>
    <feature>pushing_a_script</feature>
    <feature>re-generating_a_script_metadata_file</feature>
    <feature>remote_path_format</feature>
    <feature>running_a_script</feature>
    <feature>showing_a_script</feature>
    <feature>wmill_script</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="feature">concept/windmill/flow</dependency>
    <dependency type="feature">meta/windmill/index-5</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./flow.md</entity>
    <entity relationship="uses">../14_dependencies_in_typescript/index.mdx</entity>
    <entity relationship="uses">../../assets/cli/cli_arguments.png &apos;CLI arguments&apos;</entity>
  </related_entities>
  <examples count="14">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,advanced,concept,scripts</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Script Commands</title>
  <description>Manage scripts via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Scripts" level="1"/>
    <section name="Listing scripts" level="2"/>
    <section name="Pushing a script" level="2"/>
    <section name="Creating a new script" level="2"/>
    <section name="(Re-)Generating a script metadata file" level="2"/>
    <section name="package.json & requirements.txt" level="2"/>
    <section name="Showing a script" level="2"/>
    <section name="Running a script" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>script_management</feature>
    <feature>script_push</feature>
    <feature>script_bootstrap</feature>
    <feature>metadata_generation</feature>
    <feature>script_run</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="4">
    <example>List all scripts in workspace</example>
    <example>Push local script to remote</example>
    <example>Create new Python script</example>
    <example>Generate metadata for script</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>8</estimated_reading_time>
  <tags>windmill,cli,wmill,script,push,bootstrap,run,metadata</tags>
</doc_metadata>
-->

# Scripts

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Script Commands</title> <description>Manage scripts via CLI</d
