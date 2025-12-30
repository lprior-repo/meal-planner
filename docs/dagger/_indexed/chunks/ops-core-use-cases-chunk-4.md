---
doc_id: ops/core/use-cases
chunk_id: ops/core/use-cases#chunk-4
heading_path: ["use-cases", "Monorepo CI"]
chunk_type: prose
tokens: 269
summary: "A monorepo typically contains multiple independent projects, each of which has different test, bu..."
---
A monorepo typically contains multiple independent projects, each of which has different test, build and deployment requirements. Managing these requirements in a single CI workflow or YAML file can be incredibly complex and time-consuming.

Dagger modules provide a framework that you can use to break up this complexity and cleanly separate CI responsibilities in a monorepo without losing reusability or performance.

### Benefits

- Encapsulating workflows into shareable, reusable modules reduces code duplication and ensures a consistent CI environment for all projects. For example, a shared module could create a common build environment and leverage this for multiple projects in the monorepo.
- Dependencies between different projects in the monorepo can be accurately modeled, even across languages. For example, Dagger's own docs builder module is written in TypeScript, while the CLI builder is in Go. But the docs builder includes a generated CLI reference, and this is accurately modeled as a dependency between the CLI and docs modules
- Dagger modules can leverage a programming language's native concurrency features to run faster, resulting in quicker feedback loops.
- Dagger modules provide a way to separate, and therefore easily debug, the business logic for different workflows in a monorepo.

> **Tip:** Learn about [best practices for monorepo CI](/reference/best-practices/monorepos).
