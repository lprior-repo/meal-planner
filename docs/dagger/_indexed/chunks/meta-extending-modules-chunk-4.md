---
doc_id: meta/extending/modules
chunk_id: meta/extending/modules#chunk-4
heading_path: ["modules", "Language-native packaging"]
chunk_type: prose
tokens: 169
summary: "The structure of a Dagger module mimics that of each language's conventional packaging mechanisms..."
---
The structure of a Dagger module mimics that of each language's conventional packaging mechanisms and tools.

- **Go:** Dagger modules written for use with the Go SDK are automatically created as [Go modules](https://go.dev/ref/mod).
- **Python:** Dagger modules in Python are built to be installed, like libraries. At module creation time, a `pyproject.toml` and `uv.lock` file will automatically be created.
- **TypeScript:** Dagger modules in Typescript are built to be installed, like libraries. The runtime container installs the module code with `yarn install --production`.
- **PHP:** Dagger modules in PHP are built to be installed, like libraries. The runtime container installs the module code with `composer install`.
- **Java:** Dagger modules in Java are built as JAR files, using Maven. The runtime container builds the module code with `mvn clean package`.
