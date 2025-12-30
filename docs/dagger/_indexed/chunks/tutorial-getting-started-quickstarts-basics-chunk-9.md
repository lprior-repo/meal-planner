---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-9
heading_path: ["quickstarts-basics", "Install other modules"]
chunk_type: mixed
tokens: 98
summary: "You can group Dagger Functions into modules and share them with others."
---
You can group Dagger Functions into modules and share them with others. The [Daggerverse](https://daggerverse.dev) is a free service that indexes all publicly available Dagger modules.

Example of installing and using modules:

```
dagger install github.com/purpleclay/daggerverse/wolfi
dagger install github.com/jpadams/daggerverse/trivy@v0.5.0
```

> **Cross-language collaboration:** Dagger Functions can call other Dagger Functions, across languages. For example, a Dagger Function written in Python can call a Dagger Function written in Go, which can call another one written in TypeScript.
