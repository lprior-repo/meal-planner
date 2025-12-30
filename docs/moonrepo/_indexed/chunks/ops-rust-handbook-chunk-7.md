---
doc_id: ops/rust/handbook
chunk_id: ops/rust/handbook#chunk-7
heading_path: ["Rust handbook", "Cargo integration"]
chunk_type: code
tokens: 365
summary: "Cargo integration"
---

## Cargo integration

You can't use Rust without Cargo -- well you could but why would you do that? With moon, we're doing our best to integrate with Cargo as much as possible. Here's a few of the benefits we currently provide.

### Global binaries

Cargo supports global binaries through the [`cargo install`](https://doc.rust-lang.org/cargo/commands/cargo-install.html) command, which installs a crate to `~/.cargo/bin`, or makes it available through the `cargo <crate>` command. These are extremely beneficial for development, but they do require every developer to manually install the crate (and appropriate version) to their machine.

With moon, this is no longer an issue with the [`rust.bins`](/docs/config/toolchain#bins) setting. This setting requires a list of crates (with optional versions) to install, and moon will install them as part of the task runner install dependencies action. Furthermore, binaries will be installed with [`cargo-binstall`](https://crates.io/crates/cargo-binstall) in an effort to reduce build and compilation times.

.moon/toolchain.yml

```yaml
rust:
  bins:
    - 'cargo-make@0.35.0'
    - 'cargo-nextest'
```

At this point, tasks can be configured to run this binary as a command. The `cargo` prefix is optional, as we'll inject it when necessary.

<project>/moon.yml

```yaml
tasks:
  test:
    command: 'nextest run --workspace'
    toolchain: 'rust'
```

tip

The `cargo-binstall` crate may require a `GITHUB_TOKEN` environment variable to make GitHub Releases API requests, especially in CI. If you're being rate limited, or fail to find a download, try creating a token with necessary permissions.

### Lockfile handling

To expand our integration even further, we also take `Cargo.lock` into account, and apply the following automations when a target is being ran:

- If the lockfile does not exist, we generate one with [`cargo generate-lockfile`](https://doc.rust-lang.org/cargo/commands/cargo-generate-lockfile.html).
- We parse and extract the resolved checksums and versions for more accurate hashing.
