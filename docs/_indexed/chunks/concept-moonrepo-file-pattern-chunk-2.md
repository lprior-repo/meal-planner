---
doc_id: concept/moonrepo/file-pattern
chunk_id: concept/moonrepo/file-pattern#chunk-2
heading_path: ["File patterns", "Globs"]
chunk_type: prose
tokens: 271
summary: "Globs"
---

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
