---
doc_id: ops/tandoor/other
chunk_id: ops/tandoor/other#chunk-1
heading_path: ["Other"]
chunk_type: prose
tokens: 260
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Other</title>
  <description>!!! info &quot;Community Contributed&quot; The examples in this section were contributed by members of the community. This page especially contains some setups that might help you if you really want to go down </description>
  <created_at>2026-01-02T19:55:27.302331</created_at>
  <updated_at>2026-01-02T19:55:27.302331</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Apache + Traefik + Sub-Path" level="2"/>
    <section name="Docker + Apache + Sub-Path" level="2"/>
    <section name="WSL" level="2"/>
  </sections>
  <features>
    <feature>apache_traefik_sub-path</feature>
    <feature>docker_apache_sub-path</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>other,tandoor,advanced,operations</tags>
</doc_metadata>
-->

# Other

> **Context**: !!! info "Community Contributed" The examples in this section were contributed by members of the community. This page especially contains some setups 

!!! info "Community Contributed"
    The examples in this section were contributed by members of the community.
    This page especially contains some setups that might help you if you really want to go down a certain path but none
    of the examples are supported (as I simply am not able to give you support for them).

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.
