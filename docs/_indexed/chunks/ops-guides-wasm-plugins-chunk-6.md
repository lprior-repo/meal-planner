---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-6
heading_path: ["WASM plugins", "Absolute"]
chunk_type: code
tokens: 210
summary: "Absolute"
---

## Absolute
"file:///root/path/to/example.wasm"
```

### `github`

The `github://` protocol can be used to target and download an asset from a specific GitHub release. The location must be an organization + repository slug (owner/repo), and the release *must have* a `.wasm` asset available to download.

```
"github://moonrepo/example-repo"
```

If you are targeting releases in a monorepo, you can append the project name after the repository. The project name will be used as a prefix for tags, and will match `<name>@v?<version>` or `<name>-v?<version>` based tags.

```
"github://moonrepo/example-repo/project-name"
```

By default, the latest release will be used and cached for 7 days. If you'd prefer to target a specific release (preferred), append the release tag to the end of the location.

```
"github://moonrepo/example-repo@v1.2.3"
```

This strategy is powered by the [GitHub API](https://api.github.com/) and is subject to rate limiting. If running in a CI environment, we suggesting setting a `GITHUB_TOKEN` environment variable to authorize API requests with. If using GitHub Actions, it's as simple as:

```yaml
