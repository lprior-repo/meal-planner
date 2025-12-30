---
doc_id: ops/getting-started/installation
chunk_id: ops/getting-started/installation#chunk-9
heading_path: ["installation", "Uninstallation"]
chunk_type: mixed
tokens: 136
summary: "Remove the Dagger CLI using the following command:

```bash
sudo rm /usr/local/bin/dagger
```

Ho..."
---
Remove the Dagger CLI using the following command:

```bash
sudo rm /usr/local/bin/dagger
```

Homebrew users can alternatively use the following command:

```bash
brew uninstall dagger
```

Next, remove the Dagger container using the following commands:

```bash
docker rm --force --volumes "$(docker ps --quiet --filter='name=^dagger-engine-')"
```

Finally, remove the `dagger` sub-directory of your local cache and configuration directories (`$XDG_CACHE_HOME` and `$XDG_CONFIG_HOME` on Linux or the equivalent for other platforms):

### macOS

```bash
rm -rf ~/Library/Caches/dagger
rm -rf ~/Library/Application\ Support/dagger
```

### Linux

```bash
rm -rf ~/.cache/dagger
rm -rf ~/.config/dagger
```

> **Note:** The paths listed above are defaults and may require adjustment for your specific environment.
