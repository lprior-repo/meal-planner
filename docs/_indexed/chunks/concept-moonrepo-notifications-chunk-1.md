---
doc_id: concept/moonrepo/notifications
chunk_id: concept/moonrepo/notifications#chunk-1
heading_path: ["Terminal notifications"]
chunk_type: prose
tokens: 208
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Terminal notifications</title>
  <description>moon is able to send operating system desktop notifications for specific events in the action pipeline, on behalf of your terminal application. This is useful for continuous feedback loops and reactin</description>
  <created_at>2026-01-02T19:55:27.179231</created_at>
  <updated_at>2026-01-02T19:55:27.179231</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Setup" level="2"/>
    <section name="Linux" level="3"/>
    <section name="macOS" level="3"/>
    <section name="Windows" level="3"/>
  </sections>
  <features>
    <feature>linux</feature>
    <feature>macos</feature>
    <feature>setup</feature>
    <feature>windows</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>terminal,concept,moonrepo</tags>
</doc_metadata>
-->

# Terminal notifications

> **Context**: moon is able to send operating system desktop notifications for specific events in the action pipeline, on behalf of your terminal application. This i

v1.38.0

moon is able to send operating system desktop notifications for specific events in the action pipeline, on behalf of your terminal application. This is useful for continuous feedback loops and reacting to long-running commands while multi-tasking.

Notifications are opt-in and must be enabled with the [`notify.terminalNotifications`](/docs/config/workspace#terminalnotifications) setting.

.moon/workspace.yml

```yaml
notifier:
  terminalNotifications: 'always'
```
