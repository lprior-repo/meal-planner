---
doc_id: tutorial/windmill/ducklake
chunk_id: tutorial/windmill/ducklake#chunk-1
heading_path: ["Ducklake"]
chunk_type: prose
tokens: 258
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Ducklake</title>
  <description>import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.586398</created_at>
  <updated_at>2026-01-02T19:55:27.586398</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Getting started" level="2"/>
    <section name="Using Ducklake in scripts" level="2"/>
    <section name="DuckDB example" level="2"/>
    <section name="Using the database manager" level="2"/>
    <section name="What Ducklake does behind the scenes" level="2"/>
  </sections>
  <features>
    <feature>duckdb_example</feature>
    <feature>getting_started</feature>
    <feature>js_allFriends</feature>
    <feature>js_friend</feature>
    <feature>js_main</feature>
    <feature>js_sql</feature>
    <feature>python_main</feature>
    <feature>using_ducklake_in_scripts</feature>
    <feature>using_the_database_manager</feature>
    <feature>what_ducklake_does_behind_the_scenes</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
    <entity relationship="uses">./ducklake_images/ducklake_settings.png &apos;Ducklake settings&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_button.png &apos;S3 content&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_db_manager.png &apos;Explore ducklake&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_catalog_db.png &apos;Catalog database&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_s3_content.png &apos;S3 content&apos;</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,ducklake</tags>
</doc_metadata>
-->

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Ducklake

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

Ducklake allows you to store massive amounts of data in S3, but still query it efficiently in natural SQL language.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/ducklake_demo.mp4"
/>
<br />

[Learn more about Ducklake](https://ducklake.select/)
