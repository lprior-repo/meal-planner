---
doc_id: ops/features/reusability
chunk_id: ops/features/reusability#chunk-1
heading_path: ["reusability"]
chunk_type: prose
tokens: 252
summary: "> **Context**: Dagger lets you encapsulate common tasks and workflows in reusable, shareable Dagg..."
---
# Reusability

> **Context**: Dagger lets you encapsulate common tasks and workflows in reusable, shareable Dagger modules. These Dagger modules are simply collections of Dagger Fu...


Dagger lets you encapsulate common tasks and workflows in reusable, shareable Dagger modules. These Dagger modules are simply collections of Dagger Functions, packaged together for easy sharing and consumption. Their design is inspired by Go modules:

- **Modules are just source code**: Binary artifacts are built locally, and aggressively cached
- **Git is the source of truth**: Modules follow semantic versioning using Git tags
- **Dependencies are pinned by default**: The version you install is the version that will run
- **No dependency hell**: Since Dagger Functions are containerized, their dependencies are naturally scoped. Different modules can require different versions of the same dependency, and everything will just work
- **First-class monorepo support**: Dagger is agnostic to repository layout, and any number of Dagger modules can peacefully coexist in a [monorepo](./ops-core-use-cases.md#monorepo-ci). It's up to you how to organize your module's source code. Some like to publish each module as a dedicated repository; others like to organize all their modules together, with the Git repository acting as a "catalog"
