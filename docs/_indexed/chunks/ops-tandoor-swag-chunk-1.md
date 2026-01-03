---
doc_id: ops/tandoor/swag
chunk_id: ops/tandoor/swag#chunk-1
heading_path: ["Swag"]
chunk_type: prose
tokens: 256
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Swag</title>
  <description>!!! danger Please refer to the [official documentation](https://github.com/linuxserver/docker-swag#usage) for the container setup. This example shows just one setup that may or may not differ from you</description>
  <created_at>2026-01-02T19:55:27.306322</created_at>
  <updated_at>2026-01-02T19:55:27.306322</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Prerequisites" level="2"/>
    <section name="Installation" level="2"/>
    <section name="Download and edit Tandoor configuration" level="3"/>
    <section name="Install and configure Docker Compose" level="3"/>
    <section name="Create containers and configure swag reverse proxy" level="3"/>
    <section name="Finalize" level="3"/>
  </sections>
  <features>
    <feature>download_and_edit_tandoor_configuration</feature>
    <feature>finalize</feature>
    <feature>install_and_configure_docker_compose</feature>
    <feature>installation</feature>
    <feature>prerequisites</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>swag,tandoor,operations,docker</tags>
</doc_metadata>
-->

# Swag

> **Context**: !!! danger Please refer to the [official documentation](https://github.com/linuxserver/docker-swag#usage) for the container setup. This example shows 

!!! danger
        Please refer to the [official documentation](https://github.com/linuxserver/docker-swag#usage) for the container setup. This example shows just one setup that may or may not differ from yours in significant ways. This tutorial does not cover security measures, backups, and many other things that you might want to consider.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.
