---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-25
heading_path: ["Windmill Development Guide", "Troubleshooting"]
chunk_type: prose
tokens: 67
summary: "Troubleshooting"
---

## Troubleshooting

### "cargo not found" Error
Use `windmill-full:latest` image instead of `windmill:main`

### OpenSSL Build Errors
Use `ureq` instead of `reqwest` to avoid OpenSSL dependency

### Script Not Found
Run `wmill sync push --yes` to ensure script is deployed

### Network Connectivity
Add `Host: localhost` header if target service validates hostname
