---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-2
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "SDK fundamentals and crate setup"]
chunk_type: prose
tokens: 278
summary: "SDK fundamentals and crate setup"
---

## SDK fundamentals and crate setup

The primary SDK crate is **`wmill`** (not `windmill` or `windmill-api`). The current version is **1.601.1**, published on crates.io with Apache-2.0 licensing. A secondary crate `windmill-api` exists but is used internally by `wmill` for low-level OpenAPI operations.

### Inline dependency declaration

Windmill Rust scripts declare dependencies using a special doc-comment block at the top of the file. This replaces the traditional `Cargo.toml`:

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! reqwest = { version = "0.12", features = ["json"] }
//! wmill = "^1.0"
//! tokio = { version = "1", features = ["full"] }
//! ```text

// Your script code follows...
```python

**Critical detail**: `serde` with the `derive` feature is included by default—you do not need to declare it unless requiring additional features. You can still import `serde::Serialize` and `serde::Deserialize` directly.

### Environment variables automatically available

| Variable | Purpose |
|----------|---------|
| `WM_TOKEN` | Authentication token for API calls |
| `WM_WORKSPACE` | Current workspace name |
| `BASE_INTERNAL_URL` | Windmill API base URL (without `/api`) |
| `WM_JOB_ID` | Current job identifier |
| `WM_STATE_PATH_NEW` | State storage path |
| `WM_FLOW_PATH` | Parent flow path (if executing within a flow) |
| `WM_ROOT_FLOW_JOB_ID` | Root flow job ID for nested flows |

---
