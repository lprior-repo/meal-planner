---
doc_id: ops/tandoor/configuration
chunk_id: ops/tandoor/configuration#chunk-1
heading_path: ["Configuration"]
chunk_type: prose
tokens: 195
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Configuration</title>
  <description>This page describes all configuration options for the application server. All settings must be configured in the environment of the application server, usually by adding them to the `.env` file.</description>
  <created_at>2026-01-02T19:55:27.324014</created_at>
  <updated_at>2026-01-02T19:55:27.324014</updated_at>
  <language>en</language>
  <sections count="61">
    <section name="Required Settings" level="2"/>
    <section name="Secret Key" level="3"/>
    <section name="Allowed Hosts" level="4"/>
    <section name="Database" level="3"/>
    <section name="Password file" level="4"/>
    <section name="Connection String" level="4"/>
    <section name="Connection Options" level="4"/>
    <section name="Optional Settings" level="2"/>
    <section name="Server configuration" level="3"/>
    <section name="Port" level="4"/>
  </sections>
  <features>
    <feature>ai_integration</feature>
    <feature>allowed_hosts</feature>
    <feature>api_url_import_throttle</feature>
    <feature>application_log_level</feature>
    <feature>authentication</feature>
    <feature>captcha</feature>
    <feature>comments</feature>
    <feature>connection_options</feature>
    <feature>connection_string</feature>
    <feature>connectors</feature>
    <feature>cors_origins</feature>
    <feature>cosmetic_preferences</feature>
    <feature>csrf_trusted_origins</feature>
    <feature>database</feature>
    <feature>debug</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">[https://docs.gunicorn.org/en/stable/design.html</entity>
  </related_entities>
  <examples count="56">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>15</estimated_reading_time>
  <tags>tandoor,advanced,operations,configuration</tags>
</doc_metadata>
-->

This page describes all configuration options for the application
server. All settings must be configured in the environment of the
application server, usually by adding them to the `.env` file.
