---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-12
heading_path: ["Windmill Flows Guide", "OAuth Flow Pattern"]
chunk_type: prose
tokens: 85
summary: "OAuth Flow Pattern"
---

## OAuth Flow Pattern

See `windmill/f/fatsecret/oauth_setup.flow/flow.yaml` for complete example.

**Pattern:**
1. **Step A (Rust)**: Get auth URL, store pending token
2. **Step B (TypeScript)**: Show prompt with link + input field
3. **Step C (Rust)**: Exchange verifier for access token
4. **Step D (Rust)**: Verify connection works

**Token Storage**: Use Windmill internal resources (`wmill.set_resource()`)
- Pending tokens: `u/admin/<service>_pending_oauth` (type: `state`)
- Access tokens: `u/admin/<service>_oauth_credentials` (type: `state`)
