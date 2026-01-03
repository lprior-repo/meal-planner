---
doc_id: tutorial/windmill/data-tables
chunk_id: tutorial/windmill/data-tables#chunk-1
heading_path: ["Data tables"]
chunk_type: prose
tokens: 293
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Data tables</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.583456</created_at>
  <updated_at>2026-01-02T19:55:27.583456</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Getting started" level="2"/>
    <section name="Usage" level="2"/>
    <section name="Assets integration" level="3"/>
    <section name="Workspace-scoped" level="3"/>
    <section name="Special data table: `main`" level="3"/>
    <section name="Database types" level="2"/>
    <section name="1. Custom instance database" level="3"/>
    <section name="2. Postgres resource" level="3"/>
    <section name="Permissions" level="2"/>
  </sections>
  <features>
    <feature>1_custom_instance_database</feature>
    <feature>2_postgres_resource</feature>
    <feature>assets_integration</feature>
    <feature>database_types</feature>
    <feature>getting_started</feature>
    <feature>js_allFriends</feature>
    <feature>js_friend</feature>
    <feature>js_main</feature>
    <feature>js_sql</feature>
    <feature>permissions</feature>
    <feature>python_main</feature>
    <feature>special_data_table_main</feature>
    <feature>usage</feature>
    <feature>workspace-scoped</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">./datatable_images/datatable_settings_1.png &apos;Data Table settings&apos;</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
    <entity relationship="uses">./datatable_images/datatable_schemas.png &apos;Data Table schemas&apos;</entity>
    <entity relationship="uses">./datatable_images/datatable_asset.png &apos;Data Table asset&apos;</entity>
    <entity relationship="uses">./datatable_images/datatable_asset_flow.png &apos;Data Table asset flow&apos;</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,data</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Data tables

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

Windmill **Data Tables** let you store and query relational data with **near-zero setup** using databases managed automatically by Windmill. They provide a simple, safe, workspace-scoped way to leverage SQL inside your workflows without exposing credentials.

---
