---
doc_id: ops/tandoor/truenas-portainer
chunk_id: ops/tandoor/truenas-portainer#chunk-1
heading_path: ["Truenas Portainer"]
chunk_type: prose
tokens: 291
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Truenas Portainer</title>
  <description>!!! info &quot;Community Contributed&quot; This guide was contributed by the community and is neither officially supported, nor updated or tested.</description>
  <created_at>2026-01-02T19:55:27.312021</created_at>
  <updated_at>2026-01-02T19:55:27.312021</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="**Instructions**" level="2"/>
    <section name="1. Login to TrueNAS through your browser" level="3"/>
    <section name="2. Install Portainer" level="3"/>
    <section name="3. Install Tandoor Recipes VIA Portainer Web Editor" level="3"/>
    <section name="4. Login and Setup your new server!" level="3"/>
  </sections>
  <features>
    <feature>1_login_to_truenas_through_your_browser</feature>
    <feature>2_install_portainer</feature>
    <feature>4_login_and_setup_your_new_server</feature>
    <feature>instructions</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>truenas,tandoor,advanced,operations</tags>
</doc_metadata>
-->

# Truenas Portainer

> **Context**: !!! info "Community Contributed" This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! info "Community Contributed"
    This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.

This guide is to assist those installing Tandoor Recipes on Truenas Core using Docker and or Portainer

Docker install instructions adapted from [PhasedLogix IT Services's guide](https://getmethegeek.com/blog/2021-01-07-add-docker-capabilities-to-truenas-core/). Portainer install instructions adopted from the [Portainer Official Documentation](https://docs.portainer.io/start/install-ce/server/docker/linux). Tandoor installation on Portainer provided by users `Szeraax` and `TransatlanticFoe` on Discord (Thank you two!)
