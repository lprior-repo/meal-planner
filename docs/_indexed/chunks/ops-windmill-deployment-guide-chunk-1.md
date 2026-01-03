---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-1
heading_path: ["Windmill Deployment Guide"]
chunk_type: prose
tokens: 334
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Windmill Deployment Guide</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;guide&lt;/type&gt; &lt;category&gt;deployment&lt;/category&gt; &lt;title&gt;Windmill Deployment Guide&lt;/title&gt; &lt;description&gt;Complete guide for deploying meal-planner Windmill infrastructure including</description>
  <created_at>2026-01-02T19:55:27.342498</created_at>
  <updated_at>2026-01-02T19:55:27.342498</updated_at>
  <language>en</language>
  <sections count="57">
    <section name="Table of Contents" level="2"/>
    <section name="Prerequisites" level="2"/>
    <section name="Required Tools" level="3"/>
    <section name="Environment Setup" level="3"/>
    <section name="Windmill Setup" level="2"/>
    <section name="1. Configure Workspace" level="3"/>
    <section name="2. Initialize Project" level="3"/>
    <section name="3. Project Structure" level="3"/>
    <section name="4. wmill.yaml Configuration" level="3"/>
    <section name="Resources Configuration" level="2"/>
  </sections>
  <features>
    <feature>1_configure_workspace</feature>
    <feature>1_register_application</feature>
    <feature>2_configure_callback_urls</feature>
    <feature>2_initialize_project</feature>
    <feature>3_oauth_flow_implementation</feature>
    <feature>3_project_structure</feature>
    <feature>4_token_storage_schema</feature>
    <feature>4_wmillyaml_configuration</feature>
    <feature>5_encryption_key_generation</feature>
    <feature>accessing_variables_in_scripts</feature>
    <feature>alerting_rules</feature>
    <feature>common_cli_commands</feature>
    <feature>create_resource_types</feature>
    <feature>create_schedules</feature>
    <feature>create_variables</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="51">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>12</estimated_reading_time>
  <tags>windmill,advanced,oauth,operations</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>guide</type>
  <category>deployment</category>
  <title>Windmill Deployment Guide</title>
  <description>Complete guide for deploying meal-planner Windmill infrastructure including resources, variables, schedules, OAuth, and monitoring</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Prerequisites" level="1"/>
    <section name="Windmill Setup" level="1"/>
    <section name="Resources Configuration" level="1"/>
    <section name="Variables and Secrets" level="1"/>
    <section name="Schedules" level="1"/>
    <section name="OAuth Configuration" level="1"/>
    <section name="Database Migrations" level="1"/>
    <section name="Monitoring and Alerting" level="1"/>
    <section name="Runbook: Common Issues" level="1"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>windmill_resources</feature>
    <feature>oauth</feature>
    <feature>schedules</feature>
    <feature>monitoring</feature>
    <feature>troubleshooting</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">tandoor</dependency>
    <dependency type="service">fatsecret</dependency>
  </dependencies>
  <code_examples count="15</code_examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>30</estimated_reading_time>
  <tags>windmill,deployment,devops,infrastructure,monitoring,oauth,schedules</tags>
</doc_metadata>
-->

# Windmill Deployment Guide

> **Context**: <!-- <doc_metadata> <type>guide</type> <category>deployment</category> <title>Windmill Deployment Guide</title> <description>Complete guide for deploy

This guide covers deploying the meal-planner Windmill infrastructure, including resources, variables, schedules, OAuth configuration, database migrations, monitoring, and troubleshooting.

---
