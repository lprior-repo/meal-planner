---
doc_id: ops/general/comparison
chunk_id: ops/general/comparison#chunk-3
heading_path: ["Feature comparison", "Comparison"]
chunk_type: prose
tokens: 555
summary: "Comparison"
---

## Comparison

### Turborepo

At a high-level, Turborepo and moon seem very similar as they both claim to be task runners. They both support incremental builds, content/smart hashing, local and remote caching, parallel execution, and everything else you'd expect from a task runner. But that's where the similarities stop, because in the end, Turborepo is nothing more than a `package.json` scripts orchestrator with a caching layer. While moon also supports this, it aims to be far more with a heavy focus on the developer experience.

#### Configuration

Turborepo only supports the Node.js ecosystem, so implicitly uses a conventions based approach. It provides very little to no configuration for customizing Turborepo to your needs.

moon is language agnostic, with initial support for Node.js and its ecosystem. Because of this, moon provides a ton of configuration for customizing moon to your needs. It prefers a configuration over conventions approach, as every repository is different.

#### Projects

Turborepo infers projects from `package.json` workspaces, and does not support non-JavaScript based projects.

moon requires projects to be defined in `.moon/workspace.yml`, and supports any programming language.

#### Tasks

Turborepo requires `package.json` scripts to be defined for every project. This results in the same scripts being repeated constantly.

moon avoids this overhead by using task inheritance. No more repetition.

#### CI

Each pipeline in `turbo.json` must be individually ran as a step in CI. Scripts not configured as pipeline tasks are never ran.

moon runs every task automatically using `moon ci`, which also supports parallelism/sharding.

#### Long-term

Turborepo is in the process of being rewritten in Rust, with its codebase being shared and coupled with the new Turbopack library, a Rust based bundler. Outside of this, there are no publicly available plans for Turborepo's future.

moon plans to be so much more than a task runner, with one such facet being a repository management tool. This includes code ownership, dependency management and auditing, repository linting, in-repo secrets, and anything else we deem viable. We also plan to support additional languages as first-class citizens within our toolchain.

### Lerna

Lerna was a fantastic tool that helped the JavaScript ecosystem grow and excelled at package versioning and publishing (and still does), but it offered a very rudimentary task runner. While Lerna was able to run scripts in parallel, it wasn't the most efficient, as it did not support caching, hashing, or performant scheduling.

However, the reason Lerna is not compared in-depth, is that Lerna was unowned and unmaintained for quite some time, and has recently fallen under the Nx umbrella. Lerna is basically Nx lite now.
