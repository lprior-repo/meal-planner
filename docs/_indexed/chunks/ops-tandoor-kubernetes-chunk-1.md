---
doc_id: ops/tandoor/kubernetes
chunk_id: ops/tandoor/kubernetes#chunk-1
heading_path: ["Kubernetes"]
chunk_type: prose
tokens: 226
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Kubernetes</title>
  <description>!!! info &quot;Community Contributed&quot; This guide was contributed by the community and is neither officially supported, nor updated or tested.</description>
  <created_at>2026-01-02T19:55:27.294600</created_at>
  <updated_at>2026-01-02T19:55:27.294600</updated_at>
  <language>en</language>
  <sections count="14">
    <section name="K8s Setup" level="2"/>
    <section name="Files" level="2"/>
    <section name="10-configmap.yaml" level="3"/>
    <section name="15-secrets.yaml" level="3"/>
    <section name="20-service-account.yml" level="3"/>
    <section name="30-pvc.yaml" level="3"/>
    <section name="40-sts-postgresql.yaml" level="3"/>
    <section name="45-service-db.yaml" level="3"/>
    <section name="50-deployment.yaml" level="3"/>
    <section name="60-service.yaml" level="3"/>
  </sections>
  <features>
    <feature>10-configmapyaml</feature>
    <feature>15-secretsyaml</feature>
    <feature>20-service-accountyml</feature>
    <feature>30-pvcyaml</feature>
    <feature>40-sts-postgresqlyaml</feature>
    <feature>45-service-dbyaml</feature>
    <feature>50-deploymentyaml</feature>
    <feature>60-serviceyaml</feature>
    <feature>70-ingressyaml</feature>
    <feature>apply_the_manifets</feature>
    <feature>conclusion</feature>
    <feature>files</feature>
    <feature>k8s_setup</feature>
    <feature>updates</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
    <dependency type="service">kubernetes</dependency>
  </dependencies>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>tandoor,kubernetes,operations</tags>
</doc_metadata>
-->

# Kubernetes

> **Context**: !!! info "Community Contributed" This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! info "Community Contributed"
    This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.
