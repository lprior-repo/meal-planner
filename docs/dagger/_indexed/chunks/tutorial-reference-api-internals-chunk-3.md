---
doc_id: tutorial/reference/api-internals
chunk_id: tutorial/reference/api-internals#chunk-3
heading_path: ["api-internals", "State Representation"]
chunk_type: prose
tokens: 73
summary: "In Dagger's GraphQL API, objects expose an ID that represents the object's state at a given time."
---
In Dagger's GraphQL API, objects expose an ID that represents the object's state at a given time. Objects like `Container` and `Directory` should be thought of as collections of state.

You can save this state and reference it elsewhere (even in a different Dagger Function), then continue updating the state from the point you left off.
