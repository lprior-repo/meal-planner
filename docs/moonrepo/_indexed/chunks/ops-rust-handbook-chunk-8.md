---
doc_id: ops/rust/handbook
chunk_id: ops/rust/handbook#chunk-8
heading_path: ["Rust handbook", "FAQ"]
chunk_type: prose
tokens: 286
summary: "FAQ"
---

## FAQ

### Should we cache the `target` directory as an output?

No, we don't believe so. Both moon and Cargo support incremental caching, but they're not entirely compatible, and will most likely cause problems when used together.

The biggest factor is that moon's caching and hydration uses a tarball strategy, where each task would unpack a tarball on cache hit, and archive a tarball on cache miss. The Cargo target directory is extremely large (moon's is around 50gb), and coupling this with our tarball strategy is not viable. This would cause massive performance degradation.

However, at maximum, you *could* cache the compiled binary itself as an output, instead of the entire target directory. Example:

moon.yml

```yaml
tasks:
  build:
    command: 'cargo build --release'
    outputs: ['target/release/moon']
```

### How can we improve CI times?

Rust is known for slow build times and CI is no exception. With that being said, there are a few patterns to help alleviate this, both on the moon side and outside of it.

To start, you can cache Rust builds in CI. This is a non-moon solution to the `target` directory problem above.

1. If you use GitHub Actions, feel free to use our [moonrepo/setup-rust](https://github.com/moonrepo/setup-rust) action, which has built-in caching.
2. A more integrated solution is [sccache](https://crates.io/crates/sccache), which stores build artifacts in a cloud storage provider.
