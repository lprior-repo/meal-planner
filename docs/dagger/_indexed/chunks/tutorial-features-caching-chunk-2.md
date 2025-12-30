---
doc_id: tutorial/features/caching
chunk_id: tutorial/features/caching#chunk-2
heading_path: ["caching", "Layer caching"]
chunk_type: prose
tokens: 90
summary: "\"Layers\" are the step-wise instructions and arguments that go into building a container image, in..."
---
"Layers" are the step-wise instructions and arguments that go into building a container image, including the result of each step. As container images are built by Dagger, Dagger automatically caches the layer involved for future use.

When Dagger executes a function, it first checks if it already has the layers required by that function. If it does, these layers are automatically reused by Dagger if their inputs remain unchanged.
