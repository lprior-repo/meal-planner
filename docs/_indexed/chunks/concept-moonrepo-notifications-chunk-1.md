---
doc_id: concept/moonrepo/notifications
chunk_id: concept/moonrepo/notifications#chunk-1
heading_path: ["Terminal notifications"]
chunk_type: prose
tokens: 107
summary: "Terminal notifications"
---

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
