---
doc_id: ops/features/shell
chunk_id: ops/features/shell#chunk-5
heading_path: ["shell", "Variables"]
chunk_type: code
tokens: 164
summary: "Dagger Shell lets you save the result of any command to a variable, using the standard bash syntax."
---
Dagger Shell lets you save the result of any command to a variable, using the standard bash syntax. Values of any type can be saved to a variable, including objects.

Here's an example:

```bash
dagger <<'.'
repo=$(git https://github.com/dagger/hello-dagger | head | tree)
env=$(container | from node:23 | with-directory /app $repo | with-workdir /app)
build=$($env | with-exec npm install | with-exec npm run build | directory ./dist)
container | from nginx | with-directory /usr/share/nginx/html $build | terminal --cmd=/bin/bash
.
```

Or in interactive mode:

```bash
repo=$(git https://github.com/dagger/hello-dagger | head | tree)
env=$(container | from node:23 | with-directory /app $repo | with-workdir /app)
build=$($env | with-exec npm install | with-exec npm run build | directory ./dist)
container | from nginx | with-directory /usr/share/nginx/html $build | terminal --cmd=/bin/bash
```
