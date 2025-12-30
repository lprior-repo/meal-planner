---
doc_id: meta/extending/modules
chunk_id: meta/extending/modules#chunk-3
heading_path: ["modules", "Runtime container"]
chunk_type: prose
tokens: 178
summary: "Dagger modules run in a runtime container that's bootstrapped by the Dagger Engine, with the nece..."
---
Dagger modules run in a runtime container that's bootstrapped by the Dagger Engine, with the necessary environment to run the Dagger module's code.

- **Go:** The runtime container is currently hardcoded to run in Go 1.21 (although this may be configurable in future).
- **Python:** The runtime container is based on the [python:3.13-slim](https://hub.docker.com/_/python/tags?name=3.13-slim) base image by default, but it can be overridden by setting `requires-python`, or pinned with a `.python-version` file.
- **TypeScript:** The runtime container is currently hardcoded to run in Node.js 22.11.0. [Bun](https://bun.sh/) 1.1.38 and [Deno](https://deno.com/) 2.2.4 are experimentally supported.
- **PHP:** The runtime container is currently hardcoded to run in [php:8.3-cli-alpine](https://hub.docker.com/_/php/tags?name=8.3-cli-alpine).
- **Java:** Two containers are used by the runtime, one to build the module into a JAR file, one to run it. They are currently hardcoded to run in [maven:3.9.9-eclipse-temurin-17](https://hub.docker.com/_/maven/tags?name=3.9.9-eclipse-temurin-17) and [eclipse-temurin:23-jre-noble](https://hub.docker.com/_/eclipse-temurin/tags?name=23-jre-noble) respectively.
