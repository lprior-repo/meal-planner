---
doc_id: ops/moonrepo/handbook
chunk_id: ops/moonrepo/handbook#chunk-6
heading_path: ["Rust handbook", "Repository structure"]
chunk_type: code
tokens: 403
summary: "Repository structure"
---

## Repository structure

Rust/Cargo repositories come in two flavors: a single crate with one `Cargo.toml`, or multiple crates with many `Cargo.toml`s using [Cargo workspaces](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html). The latter is highly preferred as it enables Cargo incremental caching.

Regardless of which flavor your repository uses, in moon, both flavors are a single [moon project](/docs/concepts/project). This means that all Rust crates are grouped together into a single moon project, and the [`moon.yml`](/docs/config/project) file is located at the root relative to `Cargo.lock` and the `target` folder.

An example of this layout is demonstrated below:

**Workspaces:**

```
/
├── .moon/
├── crates/
│   ├── client/
|   │   ├── ...
│   │   └── Cargo.toml
│   ├── server/
|   │   ├── ...
│   │   └── Cargo.toml
│   └── utils/
|       ├── ...
│       └── Cargo.toml
├── target/
├── Cargo.lock
├── Cargo.toml
└── moon.yml
```

**Non-workspaces:**

```
/
├── .moon/
├── src/
│   └── lib.rs
├── tests/
│   └── ...
├── target/
├── Cargo.lock
├── Cargo.toml
└── moon.yml
```

### Example `moon.yml`

The following configuration represents a base that covers most Rust projects.

**Workspaces:**

<project>/moon.yml

```yaml
language: 'rust'
layer: 'application'

env:
  CARGO_TERM_COLOR: 'always'

fileGroups:
  sources:
    - 'crates/*/src/**/*'
    - 'crates/*/Cargo.toml'
    - 'Cargo.toml'
  tests:
    - 'crates/*/benches/**/*'
    - 'crates/*/tests/**/*'

tasks:
  build:
    command: 'cargo build'
    inputs:
      - '@globs(sources)'
  check:
    command: 'cargo check --workspace'
    inputs:
      - '@globs(sources)'
  format:
    command: 'cargo fmt --all --check'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
  lint:
    command: 'cargo clippy --workspace'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
  test:
    command: 'cargo test --workspace'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
```

**Non-workspaces:**

<project>/moon.yml

```yaml
language: 'rust'
layer: 'application'

env:
  CARGO_TERM_COLOR: 'always'

fileGroups:
  sources:
    - 'src/**/*'
    - 'Cargo.toml'
  tests:
    - 'benches/**/*'
    - 'tests/**/*'

tasks:
  build:
    command: 'cargo build'
    inputs:
      - '@globs(sources)'
  check:
    command: 'cargo check'
    inputs:
      - '@globs(sources)'
  format:
    command: 'cargo fmt --check'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
  lint:
    command: 'cargo clippy'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
  test:
    command: 'cargo test'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
```
