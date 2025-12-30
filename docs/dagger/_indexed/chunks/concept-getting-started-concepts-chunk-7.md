---
doc_id: concept/getting-started/concepts
chunk_id: concept/getting-started/concepts#chunk-7
heading_path: ["concepts", "Extending the Dagger API"]
chunk_type: prose
tokens: 179
summary: "The Dagger API is extensible and shareable by design."
---
The Dagger API is extensible and shareable by design. You can extend the API by creating Dagger [modules](./meta-extending-modules.md). You are encouraged to write your own Dagger modules and share them with others.

Dagger also lets you import and reuse modules developed by your team, your organization or the broader Dagger community. The [Daggerverse](https://daggerverse.dev) is a free service run by Dagger, which indexes all publicly available Dagger modules and Dagger functions, and lets you easily search and consume them.

When a Dagger module is loaded, the Dagger API is [dynamically extended](/reference/api/internals#dynamic-api-extension) with new Dagger Functions served by that module. So, after loading a Dagger module, an API client can now call all of the original core functions, plus the new Dagger Functions provided by that module.

You can also embed a Dagger SDK directly into your application using [Go](/extending/custom-applications/go).
