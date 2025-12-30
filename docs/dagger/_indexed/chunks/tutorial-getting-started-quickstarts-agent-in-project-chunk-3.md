---
doc_id: tutorial/getting-started/quickstarts-agent-in-project
chunk_id: tutorial/getting-started/quickstarts-agent-in-project#chunk-3
heading_path: ["quickstarts-agent-in-project", "Inspect the example application"]
chunk_type: code
tokens: 98
summary: "This quickstart uses the Daggerized project from the CI quickstart."
---
This quickstart uses the Daggerized project from the CI quickstart. To verify that your project is in the correct state, change to the project's working directory and list the available Dagger Functions:

```bash
cd hello-dagger
dagger functions
```

This should show:

```
Name        Description
build       Build the application container
build-env   Build a ready-to-use development environment
publish     Publish the application container after building and testing it on-the-fly
test        Return the result of running unit tests
```
