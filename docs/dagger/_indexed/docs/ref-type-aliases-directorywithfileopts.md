---
id: ref/type-aliases/directorywithfileopts
title: "Type Alias: DirectoryWithFileOpts"
category: ref
tags: ["directory", "ref", "file", "type"]
---

# Type Alias: DirectoryWithFileOpts

> **Context**: > **DirectoryWithFileOpts** = `object`


> **DirectoryWithFileOpts** = `object`

## Properties

### owner?

> `optional` **owner**: `string`

A user:group to set for the copied directory and its contents.

The user and group must be an ID (1000:1000), not a name (foo:bar).

If the group is omitted, it defaults to the same as the user.

---

### permissions?

> `optional` **permissions**: `number`

Permission given to the copied file (e.g., 0600).

## See Also

- [Documentation Overview](./COMPASS.md)
