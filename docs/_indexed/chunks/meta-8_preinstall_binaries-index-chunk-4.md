---
doc_id: meta/8_preinstall_binaries/index
chunk_id: meta/8_preinstall_binaries/index#chunk-4
heading_path: ["Preinstall binaries", "Example: Installing Playwright (via uv)"]
chunk_type: prose
tokens: 46
summary: "Example: Installing Playwright (via uv)"
---

## Example: Installing Playwright (via uv)

```dockerfile
FROM ghcr.io/windmill-labs/windmill-ee:main

RUN uv tool install playwright
RUN playwright install
RUN playwright install-deps

CMD ["windmill"]
```

> Note: The example above uses the enterprise edition (`windmill-ee`) as the base.
