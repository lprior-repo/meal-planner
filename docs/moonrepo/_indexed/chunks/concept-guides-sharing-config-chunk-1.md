---
doc_id: concept/guides/sharing-config
chunk_id: concept/guides/sharing-config#chunk-1
heading_path: ["Sharing workspace configuration"]
chunk_type: prose
tokens: 175
summary: "Sharing workspace configuration"
---

# Sharing workspace configuration

> **Context**: For large companies, open source maintainers, and those that love reusability, more often than not you'll want to use the same configuration across al

For large companies, open source maintainers, and those that love reusability, more often than not you'll want to use the same configuration across all repositories for consistency. This helps reduce the maintenance burden while ensuring a similar developer experience.

To help streamline this process, moon provides an `extends` setting in both [`.moon/workspace.yml`](/docs/config/workspace#extends), [`.moon/toolchain.yml`](/docs/config/toolchain#extends), and [`.moon/tasks.yml`](/docs/config/tasks#extends). This setting requires a HTTPS URL *or* relative file system path that points to a valid YAML document for the configuration in question.

A great way to share configuration is by using GitHub's "raw file view", as demonstrated below using our very own [examples repository](https://github.com/moonrepo/examples).

.moon/tasks.yml

```yaml
extends: 'https://raw.githubusercontent.com/moonrepo/examples/master/.moon/tasks.yml'
```
