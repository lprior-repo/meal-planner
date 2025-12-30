---
doc_id: tutorial/getting-started/quickstarts-blueprint
chunk_id: tutorial/getting-started/quickstarts-blueprint#chunk-5
heading_path: ["quickstarts-blueprint", "Initialize a Dagger module with a blueprint"]
chunk_type: code
tokens: 124
summary: "Create a new Dagger module using `dagger init`, but using an existing module as a blueprint:

```..."
---
Create a new Dagger module using `dagger init`, but using an existing module as a blueprint:

```bash
dagger init --blueprint=github.com/kpenfound/blueprints/hello-dagger
```

The `--blueprint` flag means the new module will use the Dagger module at [github.com/kpenfound/blueprints/hello-dagger](https://github.com/kpenfound/blueprints/tree/main/hello-dagger) as a blueprint.

See what tools have been installed:

```bash
dagger functions
```

You will see:

```
Name        Description
build       Build the application container
build-env   Build a ready-to-use development environment
publish     Publish the application container after building and testing it on-the-fly
test        Return the result of running unit tests
```

Try running the test function:

```bash
dagger call test
```
