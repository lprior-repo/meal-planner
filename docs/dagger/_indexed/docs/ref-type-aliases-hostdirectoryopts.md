---
id: ref/type-aliases/hostdirectoryopts
title: "Type Alias: HostDirectoryOpts"
category: ref
tags: ["directory", "git", "ref", "type"]
---

# Type Alias: HostDirectoryOpts

> **Context**: > **HostDirectoryOpts** = `object`


> **HostDirectoryOpts** = `object`

## Properties

### exclude?

> `optional` **exclude**: `string`[]

Exclude artifacts that match the given pattern (e.g., ["node_modules/", ".git*"]).

---

### gitignore?

> `optional` **gitignore**: `boolean`

Apply .gitignore filter rules inside the directory

---

### include?

> `optional` **include**: `string`[]

Include only artifacts that match the given pattern (e.g., ["app/", "package.*"]).

---

### noCache?

> `optional` **noCache**: `boolean`

If true, the directory will always be reloaded from the host.

## See Also

- [Documentation Overview](./COMPASS.md)
