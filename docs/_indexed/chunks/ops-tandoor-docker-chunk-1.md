---
doc_id: ops/tandoor/docker
chunk_id: ops/tandoor/docker#chunk-1
heading_path: ["Docker"]
chunk_type: prose
tokens: 260
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Docker</title>
  <description>!!! success &quot;Recommended Installation&quot; Setting up this application using Docker is recommended. This does not mean that other options are bad, but its the only method that is officially maintained and</description>
  <created_at>2026-01-02T19:55:27.286624</created_at>
  <updated_at>2026-01-02T19:55:27.286624</updated_at>
  <language>en</language>
  <sections count="17">
    <section name="**Versions**" level="2"/>
    <section name="**Docker**" level="2"/>
    <section name="**Docker Compose**" level="2"/>
    <section name="**Plain**" level="3"/>
    <section name="**Reverse Proxy**" level="3"/>
    <section name="**Traefik**" level="4"/>
    <section name="**jwilder&apos;s Nginx-proxy**" level="4"/>
    <section name="**Apache proxy**" level="4"/>
    <section name="**DockSTARTer**" level="2"/>
    <section name="**Additional Information**" level="2"/>
  </sections>
  <features>
    <feature>additional_information</feature>
    <feature>apache</feature>
    <feature>apache_proxy</feature>
    <feature>docker</feature>
    <feature>docker_compose</feature>
    <feature>dockstarter</feature>
    <feature>jwilders_nginx-proxy</feature>
    <feature>nginx</feature>
    <feature>nginx_config</feature>
    <feature>plain</feature>
    <feature>required_headers</feature>
    <feature>reverse_proxy</feature>
    <feature>setup_issues_on_raspberry_pi</feature>
    <feature>sub_path_nginx_config</feature>
    <feature>tandoor_1_vs_tandoor_2</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">traefik.md</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="13">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>tandoor,advanced,operations,docker</tags>
</doc_metadata>
-->

# Docker

> **Context**: !!! success "Recommended Installation" Setting up this application using Docker is recommended. This does not mean that other options are bad, but its

!!! success "Recommended Installation"
    Setting up this application using Docker is recommended. This does not mean that other options are bad, but its the only method 
    that is officially maintained and gets regularly tested. 

This guide shows you some basic setups using Docker and docker compose. For configuration options see the [configuration page](https://docs.tandoor.dev/system/configuration/).
