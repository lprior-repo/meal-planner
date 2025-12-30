---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-3
heading_path: ["quickstarts-basics", "Create containers"]
chunk_type: mixed
tokens: 136
summary: "Dagger works by expressing workflows as combinations of functions from the Dagger API, which expo..."
---
Dagger works by expressing workflows as combinations of functions from the Dagger API, which exposes a range of tools for working with containers, files, directories, network services, secrets. You call the Dagger API from the shell (Dagger Shell) or from code (custom Dagger Functions written in a programming language).

Dagger Shell is an interactive client for the Dagger API. You launch it by typing:

```bash
dagger
```

Here's an example of using it to build and return an Alpine container:

```
container | from alpine
```

You can open an interactive terminal session with the running container:

```
container | from alpine | terminal
```
