---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-5
heading_path: ["Security and process isolation", "More restrictive: add network isolation (still requires privileged mode)"]
chunk_type: prose
tokens: 20
summary: "More restrictive: add network isolation (still requires privileged mode)"
---

## More restrictive: add network isolation (still requires privileged mode)
UNSHARE_ISOLATION_FLAGS="--user --map-root-user --pid --fork --mount-proc --net"
