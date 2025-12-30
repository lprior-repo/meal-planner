---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-4
heading_path: ["quickstarts-basics", "Execute commands"]
chunk_type: code
tokens: 124
summary: "You can run commands in the container and return the output:

```
container | from alpine | with-..."
---
You can run commands in the container and return the output:

```
container | from alpine | with-exec uname | stdout
```

Here's an example of installing the `curl` package and using it to retrieve a webpage:

```
container | from alpine | with-exec apk add curl | with-exec curl https://dagger.io | stdout
```

### Getting Help

The Dagger API is extensively documented. Simply append `.help` to your in-progress workflow for context-sensitive assistance:

```
container | from alpine | .help
container | from alpine | .help with-directory
container | from alpine | .help with-exec
```
