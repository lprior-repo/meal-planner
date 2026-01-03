---
doc_id: tutorial/windmill/structured-databases
chunk_id: tutorial/windmill/structured-databases#chunk-1
heading_path: ["Big structured SQL data: Postgres (Supabase, Neon.tech)"]
chunk_type: prose
tokens: 218
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Big structured SQL data: Postgres (Supabase, Neon.tech)</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.599215</created_at>
  <updated_at>2026-01-02T19:55:27.599215</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Execute queries" level="2"/>
    <section name="Supabase" level="3"/>
    <section name="Neon.tech" level="3"/>
    <section name="Database studio" level="2"/>
  </sections>
  <features>
    <feature>database_studio</feature>
    <feature>execute_queries</feature>
    <feature>neontech</feature>
    <feature>supabase</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
    <dependency type="feature">meta/windmill/index-91</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">../../getting_started/0_scripts_quickstart/5_sql_quickstart/index.mdx</entity>
    <entity relationship="uses">../../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../../integrations/supabase.md</entity>
    <entity relationship="uses">/blog/database-events-from-supabase-to-windmill</entity>
    <entity relationship="uses">../../apps/7_app_e-commerce.md</entity>
    <entity relationship="uses">/blog/create-issue-tracker-in-15-minutes</entity>
    <entity relationship="uses">/blog/create-issue-tracker-part-2</entity>
    <entity relationship="uses">/blog/supabase-authentication-and-rls-protected-tables-on-windmill</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,big,beginner,sql</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Big structured SQL data: Postgres (Supabase, Neon.tech)

> **Context**: import DocCard from '@site/src/components/DocCard';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

For Postgres databases (best for structured data storage and retrieval, where you can define schema and relationships between entities), we recommend using Supabase or Neon.tech.
