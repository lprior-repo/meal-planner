---
id: concept/moonrepo/notifications
title: "Terminal notifications"
category: concept
tags: ["terminal", "concept", "moonrepo"]
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

## Setup

Notifications must be enabled at the operating system level.

### Linux

Linux support is based on the [XDG specification](https://en.wikipedia.org/wiki/XDG) and utilizes D-BUS APIs, primarily the [`org.freedesktop.Notifications.Notify`](https://www.galago-project.org/specs/notification/0.9/x408.html#command-notify) method. Refer to your desktop distribution for more information.

Notifications will be sent using the `moon` application name (the current executable).

### macOS

- Open "System Settings" or "System Preferences"
- Select "Notifications" in the left sidebar
- Select your terminal application from the list (e.g., "Terminal", "iTerm", etc)
- Ensure "Allow notifications" is enabled
- Customize the other settings as desired

Notifications will be sent from your currently running terminal application, derived from the `TERM_PROGRAM` environment variable. If we fail to detect the terminal, it will default to "Finder".

### Windows

Requires Windows 10 or later.

- Open "Settings"
- Go to the "System" panel
- Select "Notifications & Actions" in the left sidebar
- Ensure notifications are enabled

Notifications will be sent from the "Windows Terminal" app if it's currently in use, otherwise from "Microsoft PowerShell".


## See Also

- [`notify.terminalNotifications`](/docs/config/workspace#terminalnotifications)
