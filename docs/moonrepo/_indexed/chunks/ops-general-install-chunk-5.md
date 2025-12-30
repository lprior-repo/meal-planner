---
doc_id: ops/general/install
chunk_id: ops/general/install#chunk-5
heading_path: ["Install moon", "Upgrading"]
chunk_type: code
tokens: 81
summary: "Upgrading"
---

## Upgrading

If using proto, moon can be upgraded using the following command:

```
proto install moon --pin
```

Otherwise, moon can be upgraded with the `moon upgrade` command. However, this will only upgrade moon if it was installed in `~/.moon/bin`.

```
moon upgrade
```

Otherwise, you can re-run the installers above and it will download, install, and overwrite with the latest version.
