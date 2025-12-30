---
doc_id: ops/features/shell
chunk_id: ops/features/shell#chunk-1
heading_path: ["shell"]
chunk_type: mixed
tokens: 242
summary: "> **Context**: The Dagger CLI includes an interactive shell that translates the familiar Bash syn..."
---
# Interactive Shell

> **Context**: The Dagger CLI includes an interactive shell that translates the familiar Bash syntax to Dagger API requests. It's the simplest and fastest way to run...


The Dagger CLI includes an interactive shell that translates the familiar Bash syntax to Dagger API requests. It's the simplest and fastest way to run Dagger workflows directly from the command-line.

You can use it for builds, tests, ephemeral environments, deployments, or any other task you want to automate from the terminal.

> **Important:** Dagger Shell commands run as sandboxed functions, accessing host resources (files, secrets, services) only when explicitly provided as arguments. This can make commands slightly more verbose, but also more repeatable, giving you confidence to iterate quickly without second-guessing.

Here's an example of Dagger Shell in action:

```bash
container | from alpine | with-exec apk add curl | with-exec -- curl -L https://dagger.io | stdout
```

Here's another, more complex example:

```bash
container |
  from cgr.dev/chainguard/wolfi-base |
  with-exec apk add go |
  with-directory /src https://github.com/golang/example#master |
  with-workdir /src/hello |
  with-exec -- go build -o hello . |
  file ./hello |
  export ./hello-from-dagger
```
