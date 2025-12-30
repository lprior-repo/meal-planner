---
doc_id: meta/extending/index
chunk_id: meta/extending/index#chunk-2
heading_path: ["index", "Modules"]
chunk_type: prose
tokens: 182
summary: "In addition to providing a set of core functions and types, the Dagger API can be extended with c..."
---
In addition to providing a set of core functions and types, the Dagger API can be extended with custom Dagger Functions and custom types. This is achieved by creating (or installing) Dagger modules. You are encouraged to write your own Dagger modules and share them with others.

When a Dagger module is loaded, the Dagger API is [dynamically extended](/reference/api/internals#dynamic-api-extension) with new Dagger Functions served by that module. So, after loading a Dagger module, an API client can now call all of the original core functions, plus the new Dagger Functions provided by that module.

Dagger also lets you import and reuse modules developed by your team, your organization or the broader Dagger community. The [Daggerverse](https://daggerverse.dev) is a free service run by Dagger, which indexes all publicly available Dagger modules and Dagger Functions, and lets you easily search and consume them.
