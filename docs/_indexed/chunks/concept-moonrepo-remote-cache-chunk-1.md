---
doc_id: concept/moonrepo/remote-cache
chunk_id: concept/moonrepo/remote-cache#chunk-1
heading_path: ["Remote caching"]
chunk_type: prose
tokens: 378
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Remote caching</title>
  <description>Is your CI pipeline running slower than usual? Are you tired of running the same build over and over although nothing has changed? Do you wish to reuse the same local cache across other machines and e</description>
  <created_at>2026-01-02T19:55:27.189878</created_at>
  <updated_at>2026-01-02T19:55:27.189878</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="Self-hosted (v1.30.0)" level="2"/>
    <section name="Host your service" level="3"/>
    <section name="Configure remote caching" level="3"/>
    <section name="TLS and mTLS" level="4"/>
    <section name="Cloud-hosted: Depot (v1.32.0)" level="2"/>
    <section name="FAQ" level="2"/>
    <section name="What is an artifact?" level="4"/>
    <section name="Do I have to use remote caching?" level="4"/>
    <section name="Does remote caching store source code?" level="4"/>
    <section name="Does moon collect any personally identifiable information?" level="4"/>
  </sections>
  <features>
    <feature>are_artifacts_encrypted</feature>
    <feature>cloud-hosted_depot_v1320</feature>
    <feature>configure_remote_caching</feature>
    <feature>do_i_have_to_use_remote_caching</feature>
    <feature>does_remote_caching_store_source_code</feature>
    <feature>host_your_service</feature>
    <feature>self-hosted_v1300</feature>
    <feature>tls_and_mtls</feature>
    <feature>what_is_an_artifact</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/cache</entity>
    <entity relationship="uses">/docs/commands/ci</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>remote,advanced,concept,moonrepo</tags>
</doc_metadata>
-->

# Remote caching

> **Context**: Is your CI pipeline running slower than usual? Are you tired of running the same build over and over although nothing has changed? Do you wish to reus

Is your CI pipeline running slower than usual? Are you tired of running the same build over and over although nothing has changed? Do you wish to reuse the same local cache across other machines and environments? These are just a few scenarios that remote caching aims to solve.

Remote caching is a system that shares artifacts to improve performance, reduce unnecessary computation time, and alleviate resources. It achieves this by uploading hashed artifacts to a cloud storage provider, like AWS S3 or Google Cloud, and downloading them on demand when a build matches a derived hash.

To make use of remote caching, we provide 2 solutions.
