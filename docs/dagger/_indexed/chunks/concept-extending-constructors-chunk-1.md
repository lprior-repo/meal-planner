---
doc_id: concept/extending/constructors
chunk_id: concept/extending/constructors#chunk-1
heading_path: ["constructors"]
chunk_type: prose
tokens: 127
summary: "> **Context**: Every Dagger module has a constructor."
---
# Constructors

> **Context**: Every Dagger module has a constructor. The default one is generated automatically and has no arguments.


Every Dagger module has a constructor. The default one is generated automatically and has no arguments.

It's possible to write a custom constructor. The mechanism to do this is SDK-specific.

This is a simple way to accept module-wide configuration, or just to set a few attributes without having to create setter functions for them.

> **Important:** Dagger modules have only one constructor. Constructors of [custom types](./concept-extending-custom-types.md) are not registered; they are constructed by the function that chains them.
