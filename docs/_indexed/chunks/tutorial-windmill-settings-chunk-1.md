---
doc_id: tutorial/windmill/settings
chunk_id: tutorial/windmill/settings#chunk-1
heading_path: ["Settings"]
chunk_type: prose
tokens: 193
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Settings</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:28.175060</created_at>
  <updated_at>2026-01-02T19:55:28.175060</updated_at>
  <language>en</language>
  <sections count="30">
    <section name="Metadata" level="2"/>
    <section name="Summary" level="3"/>
    <section name="Path" level="3"/>
    <section name="Description" level="3"/>
    <section name="Language" level="3"/>
    <section name="Script kind" level="3"/>
    <section name="Runtime" level="2"/>
    <section name="Concurrency limits" level="3"/>
    <section name="Debouncing" level="3"/>
    <section name="Worker group tag" level="3"/>
  </sections>
  <features>
    <feature>cache</feature>
    <feature>concurrency_limits</feature>
    <feature>debouncing</feature>
    <feature>dedicated_workers</feature>
    <feature>delete_after_use</feature>
    <feature>description</feature>
    <feature>email</feature>
    <feature>generated_ui</feature>
    <feature>high_priority_script</feature>
    <feature>kafka</feature>
    <feature>language</feature>
    <feature>metadata</feature>
    <feature>mqtt_triggers</feature>
    <feature>nats</feature>
    <feature>path</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="service">docker</dependency>
    <dependency type="feature">meta/windmill/index-37</dependency>
    <dependency type="feature">meta/windmill/index-30</dependency>
    <dependency type="feature">meta/windmill/index-79</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-89</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../../static/images/script_languages.png &apos;Script settings&apos;</entity>
    <entity relationship="uses">../core_concepts/22_ai_generation/index.mdx</entity>
    <entity relationship="uses">../core_concepts/16_roles_and_permissions/index.mdx</entity>
    <entity relationship="uses">../core_concepts/8_groups_and_folders/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/4_bash_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/5_sql_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/6_rest_grapqhql_quickstart/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>7</estimated_reading_time>
  <tags>windmill,tutorial,beginner,settings</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Settings

> **Context**: import DocCard from '@site/src/components/DocCard';

Each script has settings associated with it, enabling it to be defined and configured in depth.

![Script settings](../../static/images/script_languages.png 'Script settings')
