---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-12
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Build modes and caching"]
chunk_type: prose
tokens: 72
summary: "Build modes and caching"
---

## Build modes and caching

Windmill optimizes Rust compilation:

- **Preview/test runs**: Debug mode compilation (faster builds, larger binaries)
- **Deployed scripts**: Release mode compilation (optimized performance)
- **Shared build directory**: All Rust scripts share a common build directory for cache efficiency
- **Distributed cache**: Enterprise feature stores Rust bundles in S3 for all workers

---
