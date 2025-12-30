---
doc_id: concept/extending/functions
chunk_id: concept/extending/functions#chunk-4
heading_path: ["functions", "Dagger CLI"]
chunk_type: code
tokens: 382
summary: "dagger call get-user
```

Here's what you should see:

```json
{
  \"title\": \"Mrs\",
  \"first\": \"Be..."
---
dagger call get-user
```

Here's what you should see:

```json
{
  "title": "Mrs",
  "first": "Beatrice",
  "last": "Lavigne"
}
```

> **Important:** Dagger Functions execute within containers spawned by the Dagger Engine. This "sandboxing" serves a few important purposes:
>
> 1. **Reproducibility**: Executing in a well-defined and well-controlled container ensures that a Dagger Function runs the same way every time it is invoked. It also guards against creating "hidden dependencies" on ambient properties of the execution environment that could change at any moment.
> 2. **Caching**: A reproducible containerized environment makes it possible to cache the result of Dagger Function execution, which in turn allows Dagger to automatically speed up operations.
> 3. **Security**: Even when running third-party Dagger Functions sourced from a Git repository, those Dagger Functions will not have default access to your host environment (host files, directories, environment variables, etc.). Access to these host resources can only be granted by explicitly passing them as argument values to the Dagger Function.

When implementing Dagger Functions, you are free to write arbitrary code that will execute inside the Dagger module's container. You have access to the Dagger API to make calls to the core Dagger API or other Dagger modules you depend on, but you are also free to just use the language's standard library and/or imported third-party libraries.

The process your code executes in will currently be with the `root` user, but without a full set of Linux capabilities and other standard container sandboxing provided by `runc`.

The current working directory of your code will be an initially empty directory. You can write and read files and directories in this directory if needed. This includes using the `Container.export()`, `Directory.export()` or `File.export()` APIs to write those artifacts to this local directory if needed.
