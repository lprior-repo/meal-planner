---
doc_id: ops/moonrepo/project
chunk_id: ops/moonrepo/project#chunk-8
heading_path: ["project", "`project`"]
chunk_type: code
tokens: 302
summary: "`project`"
---

## `project`

The `project` setting defines metadata about the project itself.

moon.yml

```yaml
project:
  name: 'moon'
  description: 'A monorepo management tool.'
  channel: '#moon'
  owner: 'infra.platform'
  maintainers: ['miles.johnson']
```

The information listed within `project` is purely informational and primarily displayed within the CLI. However, this setting exists for you, your team, and your company, as a means to identify and organize all projects. Feel free to build your own tooling around these settings!

### `channel`

The Slack, Discord, Teams, IRC, etc channel name (with leading #) in which to discuss the project.

### `description` (Required)

A description of what the project does and aims to achieve. Be as descriptive as possible, as this is the kind of information search engines would index on.

### `maintainers`

A list of people/developers that maintain the project, review code changes, and can provide support. Can be a name, email, LDAP name, GitHub username, etc, the choice is yours.

### `metadata` (v1.27.0)

A map of custom metadata to associate to this project. Supports all value types that are valid JSON.

moon.yml

```yaml
project:
  # ...
  metadata:
    deprecated: true
```

### `name`

A human readable name of the project. This is *different* from the unique project name configured in [`projects`](/docs/config/workspace#projects).

### `owner`

The team or organization that owns the project. Can be a title, LDAP name, GitHub team, etc. We suggest *not* listing people/developers as the owner, use [maintainers](#maintainers) instead.
