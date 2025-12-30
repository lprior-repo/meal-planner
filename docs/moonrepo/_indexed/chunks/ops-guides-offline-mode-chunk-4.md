---
doc_id: ops/guides/offline-mode
chunk_id: ops/guides/offline-mode#chunk-4
heading_path: ["Offline mode", "Environment variables"]
chunk_type: prose
tokens: 76
summary: "Environment variables"
---

## Environment variables

Some additional variables to interact with offline checks.

- `PROTO_OFFLINE_TIMEOUT` - Customize the timeout for offline checks (in milliseconds). Defaults to `750`.
- `PROTO_OFFLINE_HOSTS` - Customize additional hosts/IPs to check for offline status. Separate multiple hosts with a `,`.
- `PROTO_OFFLINE_IP_VERSION` - Customize which IP version to support, `4` or `6`. If not defined, supports both.
