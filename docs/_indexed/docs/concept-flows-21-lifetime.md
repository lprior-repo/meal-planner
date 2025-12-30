---
id: concept/flows/21-lifetime
title: "Lifetime / Delete after use"
category: concept
tags: ["flows", "lifetime", "concept"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Lifetime</title>
  <description>Delete flow step logs after completion for privacy</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Lifetime / Delete after use" level="1"/>
  </sections>
  <features>
    <feature>lifetime</feature>
    <feature>privacy</feature>
    <feature>data_retention</feature>
    <feature>automatic_deletion</feature>
  </features>
  <dependencies>
    <dependency type="feature">data_security</dependency>
  </dependencies>
  <examples count="1">
    <example>Sensitive data processing logs</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,lifetime,delete,logs,privacy,security,data-retention</tags>
</doc_metadata>
-->

# Lifetime / Delete after use

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Lifetime</title> <description>Delete flow step logs after completion for 

The logs, arguments and results of this flow step will be completely deleted from Windmill once the flow is complete. They might be temporarily visible in UI while the flow is running.
This also applies to a flow step that has failed: the error will not be accessible.

The deletion is irreversible.

![Lifetime / Delete after use](../assets/flows/flow_lifetime.png "Lifetime / Delete after use")

This feature is exclusive to [Cloud plans and Self-Hosted Enterprise](/pricing).

## See Also

- [Lifetime / Delete after use](../assets/flows/flow_lifetime.png "Lifetime / Delete after use")
- [Cloud plans and Self-Hosted Enterprise](/pricing)
