---
id: concept/moonrepo/sync
title: "sync"
category: concept
tags: ["moonrepo", "concept", "sync"]
---

# sync

> **Context**: Operations for syncing the workspace to a healthy state.

Operations for syncing the workspace to a healthy state.

## codeowners

The moon sync codeowners command will manually sync code owners, by aggregating all owners from projects, and generating a single `CODEOWNERS` file.

## config-schemas

The moon sync config-schemas command will manually generate JSON schemas to .moon/cache/schemas for all configuration files.

## hooks

The moon sync hooks command will manually sync hooks for the configured VCS.

## projects

The moon sync projects command will force sync all projects in the workspace to help achieve a healthy repository state.


## See Also

- [Documentation Index](./COMPASS.md)
