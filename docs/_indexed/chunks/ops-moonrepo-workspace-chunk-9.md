---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-9
heading_path: [".moon/workspace.{pkl,yml}", "`notifier`"]
chunk_type: prose
tokens: 58
summary: "`notifier`"
---

## `notifier`

Configures how moon notifies and interacts with a developer or an external system.

### `webhookUrl`

Defines an HTTPS URL that all pipeline events will be posted to. View the [webhooks guide for more information](/docs/guides/webhooks) on available events.

.moon/workspace.yml

```yaml
notifier:
  webhookUrl: 'https://api.company.com/some/endpoint'
```
