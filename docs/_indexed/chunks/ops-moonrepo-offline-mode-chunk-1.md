---
doc_id: ops/moonrepo/offline-mode
chunk_id: ops/moonrepo/offline-mode#chunk-1
heading_path: ["Offline mode"]
chunk_type: prose
tokens: 204
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Offline mode</title>
  <description>moon assumes that an internet connection is always available, as we download and install tools into the toolchain, resolve versions against upstream manifests, and automatically install dependencies. </description>
  <created_at>2026-01-02T19:55:27.180727</created_at>
  <updated_at>2026-01-02T19:55:27.180727</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="What&apos;s disabled when offline" level="2"/>
    <section name="Toggling modes" level="2"/>
    <section name="Environment variables" level="2"/>
  </sections>
  <features>
    <feature>environment_variables</feature>
    <feature>toggling_modes</feature>
    <feature>whats_disabled_when_offline</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>offline,operations,moonrepo</tags>
</doc_metadata>
-->

# Offline mode

> **Context**: moon assumes that an internet connection is always available, as we download and install tools into the toolchain, resolve versions against upstream m

moon assumes that an internet connection is always available, as we download and install tools into the toolchain, resolve versions against upstream manifests, and automatically install dependencies. While this is useful, having a constant internet connection isn't always viable.

To support workflows where internet isn't available or is spotty, moon will automatically check for an active internet connection, and drop into offline mode if necessary.
