---
doc_id: tutorial/getting-started/quickstarts-ci
chunk_id: tutorial/getting-started/quickstarts-ci#chunk-6
heading_path: ["quickstarts-ci", "Construct a workflow"]
chunk_type: prose
tokens: 112
summary: "Replace the generated Dagger module files with code that adds four Dagger Functions:

- The `publ..."
---
Replace the generated Dagger module files with code that adds four Dagger Functions:

- The `publish` Dagger Function tests, builds and publishes a container image of the application to a registry.
- The `test` Dagger Function runs the application's unit tests and returns the results.
- The `build` Dagger Function performs a multi-stage build and returns a final container image with the production-ready application and an NGINX Web server.
- The `build-env` Dagger Function creates a container with the build environment for the application.

**Go (`main.go`):**
