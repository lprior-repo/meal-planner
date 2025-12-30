---
id: ref/type-aliases/functionwithargopts
title: "Type Alias: FunctionWithArgOpts"
category: ref
tags: ["ref", "type", "directory", "function", "go"]
---

# Type Alias: FunctionWithArgOpts

> **Context**: > **FunctionWithArgOpts** = `object`


> **FunctionWithArgOpts** = `object`

## Properties

### defaultPath?

> `optional` **defaultPath**: `string`

If the argument is a Directory or File type, default to load path from context directory, relative to root directory.

---

### defaultValue?

> `optional` **defaultValue**: `JSON`

A default value to use for this argument if not explicitly set by the caller, if any

---

### deprecated?

> `optional` **deprecated**: `string`

If deprecated, the reason or migration path.

---

### description?

> `optional` **description**: `string`

A doc string for the argument, if any

---

### ignore?

> `optional` **ignore**: `string`[]

Patterns to ignore when loading the contextual argument value.

---

### sourceMap?

> `optional` **sourceMap**: `SourceMap`

The source map for the argument definition.

## See Also

- [Documentation Overview](./COMPASS.md)
