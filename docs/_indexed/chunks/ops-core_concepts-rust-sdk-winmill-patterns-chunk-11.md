---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-11
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Limitations compared to TypeScript and Python"]
chunk_type: prose
tokens: 176
summary: "Limitations compared to TypeScript and Python"
---

## Limitations compared to TypeScript and Python

| Feature | TypeScript/Python | Rust |
|---------|-------------------|------|
| **Dedicated workers** | ✅ Persistent processes | ❌ Not available |
| **Result streaming** | ✅ `wmill.streamResult()` | ❌ Not available |
| **Workflows as code** | ✅ Full support | ❌ Use flow editor or YAML |
| **Native runtime parallelization** | ✅ 8x via nativets | ❌ Different performance model |
| **Cold start time** | Fast | Slower (compilation required) |

### Workarounds

- **No dedicated workers**: Accept cold start overhead; Rust compilation caching mitigates this
- **No result streaming**: Return complete results; use `set_progress()` for status updates
- **No workflows-as-code**: Define flows in the UI or YAML; call Rust scripts as steps
- **Cold starts**: Use debug mode during development (faster), release mode for deployment

---
