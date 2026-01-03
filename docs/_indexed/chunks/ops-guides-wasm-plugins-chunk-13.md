---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-13
heading_path: ["WASM plugins", "https://github.com/WebAssembly/wabt"]
chunk_type: code
tokens: 178
summary: "https://github.com/WebAssembly/wabt"
---

## https://github.com/WebAssembly/wabt
~/wabt/bin/wasm-strip "$output"
```

### Manually create releases

When your plugin is ready to be published, you can create a release on GitHub using the following steps.

1. Tag the release and push to GitHub.

```shell
git tag v0.0.1
git push --tags
```

2. Build a release version of the plugin using the `build-wasm` script above. The file will be available at `target/wasm32-wasip1/<name>.wasm`.

```shell
build-wasm <name>
```

3. In GitHub, navigate to the tags page, find the new tag, create a new release, and attach the built file as an asset.

### Automate releases

If you're using GitHub Actions, you can automate the release process with our official [moonrepo/build-wasm-plugin](https://github.com/moonrepo/build-wasm-plugin) action.

1. Create a new workflow file at `.github/workflows/release.yml`. Refer to the link above for a working example.

2. Tag the release and push to GitHub.

```shell
