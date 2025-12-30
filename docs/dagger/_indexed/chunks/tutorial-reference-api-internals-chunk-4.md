---
doc_id: tutorial/reference/api-internals
chunk_id: tutorial/reference/api-internals#chunk-4
heading_path: ["api-internals", "Lazy Evaluation"]
chunk_type: code
tokens: 118
summary: "GraphQL query resolution is triggered only when a leaf value (scalar) is requested."
---
GraphQL query resolution is triggered only when a leaf value (scalar) is requested. Dagger uses this feature to evaluate workflows "lazily."

In practice, this means that if you create a Dagger object but never access its state, Dagger automatically skips it as part of its optimization process.

There are cases where this behavior causes unexpected results, such as when the command has external effects. Use the `sync` field to forcefully execute the step:

```graphql
query {
  container {
    from(address: "alpine:latest") {
      withExec(args: ["curl", "YOUR-WEBHOOK-URL"]) {
        sync
      }
    }
  }
}
```
