---
doc_id: ops/moonrepo/comparison
chunk_id: ops/moonrepo/comparison#chunk-4
heading_path: ["Feature comparison", "Comparison tables"]
chunk_type: prose
tokens: 2187
summary: "Comparison tables"
---

## Comparison tables

### Workspace

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Core/CLI written in | Rust | Node.js & Rust (for hot paths) | Rust / Go |
| Plugins written in | WASM (any compatible language) | TypeScript | Not supported |
| Workspace configured with | `.moon/workspace.yml` | `nx.json` | `turbo.json` |
| Project list configured in | `.moon/workspace.yml` | `workspace.json` / `package.json` workspaces | `package.json` workspaces |
| Repo / folder structure | loose | loose | loose |
| Ignore file support | Yes via `hasher.ignorePatterns` | Yes .nxignore | Yes via `--ignore` |
| Supports dependencies inherited by all tasks | Yes via `implicitDeps` | Yes via `targetDefaults` | No |
| Supports inputs inherited by all tasks | Yes via `implicitInputs` | Yes via `implicitDependencies` | Yes via `globalDependencies` |
| Supports tasks inherited by all projects | Yes | Yes via `plugins` | No |
| Integrates with a version control system | Yes git | Yes git | Yes git |
| Supports scaffolding / generators | Yes | Yes | Yes |

### Toolchain

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Supported languages in task runner | All languages available on `PATH` | All languages via plugins. OOTB TS/JS, existing plugins for Rust, Go, Dotnet and more | JavaScript/TypeScript via `package.json` scripts |
| Supported dependency managers | npm, pnpm, yarn, bun | npm, pnpm, yarn | npm, pnpm, yarn |
| Supported toolchain languages (automatic dev envs) | Bun, Deno, Node.js, Rust | No | No |
| Has a built-in toolchain | Yes | No | No |
| Downloads and installs languages (when applicable) | Yes | No | No |
| Configures explicit language/dependency manager versions | Yes | No | No |

### Projects

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Dependencies on other projects | Yes implicit from `package.json` or explicit in `moon.yml` | Yes implicit from `package.json` or explicit in `project.json` and code imports/exports | Yes implicit from `package.json` |
| Ownership metadata | Yes | No | No |
| Primary programming language | Yes | No | No |
| Project type (app, lib, etc) | Yes app, lib, tool, automation, config, scaffold | Yes app, lib | No |
| Project tech stack | Yes frontend, backend, infra, systems | No | No |
| Project-level file groups | Yes | Yes via `namedInputs` | No |
| Project-level tasks | Yes | Yes | Yes |
| Tags and scopes (boundaries) | Yes native for all languages | Yes boundaries via ESLint (TS and JS), tags for filtering for all languages | No |

### Tasks

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Known as | tasks | targets | tasks |
| Defines tasks in | `moon.yml` or `package.json` scripts | `nx.json`, `project.json` or `package.json` scripts | `package.json` scripts |
| Run a single task with | `moon run project:task` | `nx target project` or `nx run project:target` | `turbo run task --filter=project` |
| Run multiple tasks with | `moon run :task` or `moon run a:task b:task` or `moon check` | `nx run-many -t task1 task2 task3` | `turbo run task` or `turbo run a b c` |
| Run tasks based on a query/filter | `moon run :task --query "..."` | `nx run-many -t task -p "tag:.." -p "dir/*" -p "name*" -p "!negation"` | No |
| Can define tasks globally | Yes with `.moon/tasks.yml` | Partial with `targetDefaults` | No |
| Merges or overrides global tasks | Yes | Yes | No |
| Runs a command with args | Yes | Yes | Partial within the script |
| Runs commands from | project or workspace root | current working directory, or wherever desired via config | project root |
| Supports pipes, redirects, etc, in configured tasks | Partial encapsulated in a file | Partial within the executor or script | Partial within the script |
| Dependencies on other tasks | Yes via `deps` | Yes via `dependsOn` | Yes via `dependsOn` |
| Can provide extra params for task dependencies | Yes | Yes | No |
| Can mark a task dependency as optional | Yes via `optional` | No | No |
| Can depend on arbitrary or unrelated tasks | Yes | Yes | No dependent projects only |
| Runs task dependencies in parallel | Yes | Yes | Yes |
| Can run task dependencies in serial | Yes | Yes via `parallel=1` | Yes via `concurrency=1` |
| File groups | Yes | Yes via `namedInputs` | No |
| Environment variables | Yes via `env`, `envFile` | Yes automatically via `.env` files and/or inherited from shell | Partial within the script |
| Inputs | Yes files, globs, env vars | Yes files, globs, env vars, runtime | Yes files, globs |
| Outputs | Yes files, globs | Yes files, globs | Yes files, globs |
| Output logging style | Yes via `outputStyle` | Yes via `--output-style` | Yes via `outputMode` |
| Custom hash inputs | No | Yes via `runtime` inputs | Yes via `globalDependencies` |
| Token substitution | Yes token functions and variable syntax | Yes `{workspaceRoot}`, `{projectRoot}`, `{projectName}`, arbitrary patterns `namedInputs` | No |
| Configuration presets | Yes via task `extends` | Yes via `configurations` | No |
| Configurable options | Yes | Yes | Yes |

### Task runner

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Known as | action pipeline | task runner | pipeline |
| Generates a dependency graph | Yes | Yes | Yes |
| Runs in topological order | Yes | Yes | Yes |
| Automatically retries failed tasks | Yes | Yes when flakiness detected on Nx Cloud | No |
| Caches task outputs via a unique hash | Yes | Yes | Yes |
| Can customize the underlying runner | No | Yes | No |
| Can profile running tasks | Yes cpu, heap | Yes cpu | Yes cpu |
| Can generate run reports | Yes | Yes free in Nx Cloud & GitHub App Comment | Yes |
| Continuous integration (CI) support | Yes | Yes | Partial |
| Continuous deployment (CD) support | No | Partial via `nx release` | No |
| Remote / cloud caching and syncing | Yes with Bazel REAPI (free / paid) | Yes with nx.app Nx Cloud (free / paid) | Yes requires a Vercel account (free) |

### Generator

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Known as | generator | generator | generator |
| Templates are configured with a schema | Yes via `template.yml` | Yes | No |
| Template file extensions (optional) | Yes .tera, .twig | Yes fully under user control, built in utility for .ejs templates | Yes .hbs |
| Template files support frontmatter | Yes | Yes fully under user control | No |
| Creates/copies files to destination | Yes | Yes | Yes |
| Updates/merges with existing files | Yes JSON/YAML only | Yes via TypeScript/JavaScript plugins | Yes |
| Renders with a template engine | Yes via Tera | Yes fully under user control, built in utility for .ejs templates | Yes via Handlebars |
| Variable interpolation in file content | Yes | Yes | Yes |
| Variable interpolation in file paths | Yes | Yes | Yes |
| Can define variable values via interactive prompts | Yes | Yes using JSON schema | Yes |
| Can define variable values via command line args | Yes | Yes using JSON schema | Yes |
| Supports dry runs | Yes | Yes | No |
| Supports render helpers, filters, and built-ins | Yes | Yes | Yes |
| Generators can compose other generators | Yes via `extends` | Yes fully under user control, author in TypeScript/JavaScript | Yes using JavaScript |

### Other systems

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Can send webhooks for critical pipeline events | Yes | No | No |
| Generates run reports with granular stats/metrics | Yes | No | Yes |
| Can define and manage code owners | Yes | No | No |
| Can generate a `CODEOWNERS` file | Yes | No | No |
| Can define and manage VCS (git) hooks | Yes | No | No |
| Supports git worktrees | Yes | No | No |

### JavaScript ecosystem

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Will automatically install node modules when lockfile changes | Yes | No | No |
| Can automatically dedupe when lockfile changes | Yes | No | No |
| Can alias `package.json` names for projects | Yes | Yes | No |
| Can add `engines` constraint to root `package.json` | Yes | No | No |
| Can sync version manager configs (`.nvmrc`, etc) | Yes | No | No |
| Can sync cross-project dependencies to `package.json` | Yes | No | No |
| Can sync project references to applicable `tsconfig.json` | Yes | No | No |
| Can auto-create missing `tsconfig.json` | Yes | No | No |
| Can sync dependencies as `paths` to `tsconfig.json` | Yes | No | No |
| Can route `outDir` to a shared cached in `tsconfig.json` | Yes | No | No |

### Docker integration

| Feature | moon | nx | turborepo |
|---------|------|-----|-----------|
| Efficient scaffolding for Dockerfile layer caching | Yes | Similar via custom generator | Yes |
| Automatic production-only dependency installation | Yes | Partial generated automatically by first party plugin | No |
| Environment pruning to reduce image/container sizes | Yes | No | Yes |
