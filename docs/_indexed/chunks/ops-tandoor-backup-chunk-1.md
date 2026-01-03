---
doc_id: ops/tandoor/backup
chunk_id: ops/tandoor/backup#chunk-1
heading_path: ["Backup"]
chunk_type: prose
tokens: 252
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Backup</title>
  <description>There is currently no &quot;good&quot; way of backing up your data implemented in the application itself. This mean that you will be responsible for backing up your data.</description>
  <created_at>2026-01-02T19:55:27.321036</created_at>
  <updated_at>2026-01-02T19:55:27.321036</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Database" level="2"/>
    <section name="Mediafiles" level="2"/>
    <section name="Manual backup from docker build" level="2"/>
    <section name="Backup using export and import" level="2"/>
    <section name="Backing up using the pgbackup container" level="2"/>
  </sections>
  <features>
    <feature>backing_up_using_the_pgbackup_container</feature>
    <feature>backup_using_export_and_import</feature>
    <feature>database</feature>
    <feature>manual_backup_from_docker_build</feature>
    <feature>mediafiles</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>tandoor,advanced,backup,operations</tags>
</doc_metadata>
-->

# Backup

> **Context**: There is currently no "good" way of backing up your data implemented in the application itself. This mean that you will be responsible for backing up 

There is currently no "good" way of backing up your data implemented in the application itself.
This mean that you will be responsible for backing up your data.

It is planned to add a "real" backup feature similar to applications like homeassistant where a snapshot can be
downloaded and restored through the web interface.

!!! warning
    When developing a new backup strategy, make sure to also test the restore process!
