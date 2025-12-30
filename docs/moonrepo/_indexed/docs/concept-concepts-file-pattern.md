---
id: concept/concepts/file-pattern
title: "File patterns"
category: concept
tags: ["concept", "file", "javascript", "concepts", "rust"]
---

# File patterns

> **Context**: Globs in moon are [Rust-based globs](https://github.com/olson-sean-k/wax), *not* JavaScript-based. This may result in different or unexpected results.

## Globs

Globs in moon are [Rust-based globs](https://github.com/olson-sean-k/wax), *not* JavaScript-based. This may result in different or unexpected results. The following guidelines must be met when using globs:

-   Must use forward slashes (`/`) for path separators, even on Windows.
-   Must *not* start with or use any relative path parts, `.` or `..`.

### Supported syntax

-   `*` - Matches zero or more characters, but does not match the `/` character. Will attempt to match the longest possible text (eager).
-   `$` - Like `*`, but will attempt to match the shortest possible text (lazy).
-   `**` - Matches zero or more directories.
-   `?` - Matches exactly one character, but not `/`.
-   `[abc]` - Matches one case-sensitive character listed in the brackets.
-   `[!xyz]` - Like the above, but will match any character *not* listed.
-   `[a-z]` - Matches one case-sensitive character in range in the brackets.
-   `[!x-z]` - Like the above, but will match any character *not* in range.
-   `{glob,glob}` - Matches one or more comma separated list of sub-glob patterns.
-   `<glob:n,n>` - Matches a sub-glob within a defined bounds.
-   `!` - At the start of a pattern, will negate previous positive patterns.

### Examples

```
README.{md,mdx,txt}
src/**/*
tests/**/*.?js
!**/__tests__/**/*
logs/<[0-9]:4>-<[0-9]:2>-<[0-9]:2>.log
```

## Project relative

When configuring [`fileGroups`](/docs/config/project#filegroups), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), all listed file paths and globs are relative from the project root they will be ran in. They *must not* traverse upwards with `..`.

```
## Valid
src/**/*
./src/**/*
package.json

## Invalid
../utils
```

## Workspace relative

When configuring [`fileGroups`](/docs/config/project#filegroups), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), a listed file path or glob can be prefixed with `/` to resolve relative from the workspace root, and *not* the project root.

```
## In project
package.json

## In workspace
/package.json
```


## See Also

- [`fileGroups`](/docs/config/project#filegroups)
- [`inputs`](/docs/config/project#inputs)
- [`outputs`](/docs/config/project#outputs)
- [`fileGroups`](/docs/config/project#filegroups)
- [`inputs`](/docs/config/project#inputs)
