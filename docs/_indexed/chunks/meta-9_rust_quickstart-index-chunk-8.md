---
doc_id: meta/9_rust_quickstart/index
chunk_id: meta/9_rust_quickstart/index#chunk-8
heading_path: ["Rust quickstart", "Fast development iteration"]
chunk_type: prose
tokens: 130
summary: "Fast development iteration"
---

## Fast development iteration

Windmill optimizes Rust development for faster iteration cycles. When developing and testing scripts:

- **Debug mode builds**: Preview and test runs use debug mode compilation, which is significantly faster to build but produces unoptimized binaries
- **Shared build directory**: All Rust scripts share a common build directory, reducing redundant compilation and improving cache efficiency
- **Release mode deployment**: When scripts are deployed to production, they are compiled in release mode for optimal performance

This approach provides the best of both worlds - fast development cycles during script creation and testing, with optimized performance in production deployments.
