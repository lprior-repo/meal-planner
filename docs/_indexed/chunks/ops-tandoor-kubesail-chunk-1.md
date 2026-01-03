---
doc_id: ops/tandoor/kubesail
chunk_id: ops/tandoor/kubesail#chunk-1
heading_path: ["Kubesail"]
chunk_type: prose
tokens: 245
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Kubesail</title>
  <description>!!! info &quot;Community Contributed&quot; This guide was contributed by the community and is neither officially supported, nor updated or tested.</description>
  <created_at>2026-01-02T19:55:27.297215</created_at>
  <updated_at>2026-01-02T19:55:27.297215</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Quick Start" level="2"/>
    <section name="Important notes" level="2"/>
  </sections>
  <features>
    <feature>important_notes</feature>
    <feature>quick_start</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
    <dependency type="service">kubernetes</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">[docs/install/k8s](https://github.com/vabene1111/recipes/tree/develop/docs/install/k8s</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tandoor,kubesail,operations</tags>
</doc_metadata>
-->

# Kubesail

> **Context**: !!! info "Community Contributed" This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! info "Community Contributed"
    This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.

[KubeSail](https://kubesail.com/) lets you install Tandoor by providing a simple web interface for installing and managing apps. You can connect any server running Kubernetes, or get a pre-configured [PiBox](https://pibox.io).

<!-- A portion of every PiBox sale goes toward supporting Tandoor development. -->

The KubeSail template is closely based on the [Kubernetes installation]([docs/install/k8s](https://github.com/vabene1111/recipes/tree/develop/docs/install/k8s)) configs
