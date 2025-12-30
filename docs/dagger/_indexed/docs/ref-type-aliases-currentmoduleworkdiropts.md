---
id: ref/type-aliases/currentmoduleworkdiropts
title: "Type Alias: CurrentModuleWorkdirOpts"
category: ref
tags: ["git", "ref", "type", "module"]
---

# Type Alias: CurrentModuleWorkdirOpts

> **Context**: > **CurrentModuleWorkdirOpts** = `object`


> **CurrentModuleWorkdirOpts** = `object`

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

## See Also

- [Documentation Overview](./COMPASS.md)
