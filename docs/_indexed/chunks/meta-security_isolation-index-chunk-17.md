---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-17
heading_path: ["Security and process isolation", "Enable if disabled (requires root)"]
chunk_type: prose
tokens: 11
summary: "Enable if disabled (requires root)"
---

## Enable if disabled (requires root)
sysctl -w kernel.unprivileged_userns_clone=1
