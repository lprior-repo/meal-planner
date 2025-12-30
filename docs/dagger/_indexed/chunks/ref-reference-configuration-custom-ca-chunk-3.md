---
doc_id: ref/reference/configuration-custom-ca
chunk_id: ref/reference/configuration-custom-ca#chunk-3
heading_path: ["configuration-custom-ca", "Configuration Applied to User Containers"]
chunk_type: prose
tokens: 83
summary: "Dagger provides best-effort support for automatically installing custom CAs in all containers cre..."
---
Dagger provides best-effort support for automatically installing custom CAs in all containers created by user workflows.

Supported base distributions:
- Alpine
- Debian-based (e.g., `debian` and `ubuntu`)
- Redhat-based (e.g., `rhel`, `fedora`, `centos`, etc.)

Behavior:
- If installation fails, the error is logged but execution continues
- When the container exits, the CAs are automatically removed to prevent leaking into cache or published images
