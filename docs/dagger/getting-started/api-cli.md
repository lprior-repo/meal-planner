# Using the Dagger CLI

The Dagger CLI lets you call both the core and extended Dagger API (the core APIs plus the new APIs provided by external Dagger modules) directly from the command-line.

You can call the API interactively (`dagger`) or non-interactively (`dagger -c`, `dagger call`, or `dagger core`).

## Examples

Here are a few examples:

### Create a simple workflow

Create a simple workflow that is fully satisfied by the core Dagger API, without needing to program a Dagger module:

**System shell:**
```bash
dagger <<EOF
container |
  from cgr.dev/chainguard/wolfi-base |
  with-exec apk add go |
  with-directory /src https://github.com/golang/example#master |
  with-workdir /src/hello |
  with-exec -- go build -o hello . |
  file ./hello |
  export ./hello-from-dagger
EOF
```

**Dagger CLI:**
```bash
dagger core container from --address="cgr.dev/chainguard/wolfi-base" \
  with-exec --args="apk","add","go" \
  with-directory --path="/src" --directory="https://github.com/golang/example#master" \
  with-workdir --path="/src/hello" \
  with-exec --args="go","build","-o","hello","." \
  file --path="./hello" \
  export --path="./hello-from-dagger"
```

### Use Dagger as an alternative to docker run

**System shell:**
```bash
dagger -c 'container | from cgr.dev/chainguard/wolfi-base | terminal'
```

**Dagger CLI:**
```bash
dagger core container \
  from --address=cgr.dev/chainguard/wolfi-base \
  terminal
```

> **Tip:** If only the core Dagger API is needed, the `-M` (`--no-mod`) flag can be provided. This results in quicker startup, because the Dagger CLI doesn't try to find and load a current module. This also makes `dagger -M` equivalent to `dagger core`.

### Call auto-generated Dagger Functions

**System shell:**
```bash
dagger -c 'container-echo "Welcome to Dagger!" | stdout'
```

**Dagger CLI:**
```bash
dagger call container-echo --string-arg="Welcome to Dagger!" stdout
```

> **Tip:** When using the Dagger CLI, all names (functions, arguments, struct fields, etc) are converted into a shell-friendly "kebab-case" style.

### Call remote modules

Modules don't need to be installed locally. Dagger lets you consume modules from GitHub repositories and call their Dagger Functions as though you were calling them locally:

**System shell:**
```bash
dagger <<EOF
github.com/jpadams/daggerverse/trivy@v0.5.0 |
  scan-image ubuntu:latest
EOF
```

**Dagger CLI:**
```bash
dagger -m github.com/jpadams/daggerverse/trivy@v0.5.0 call \
  scan-image --image-ref=ubuntu:latest
```

### List available functions

List all the Dagger Functions available in a module using context-sensitive help:

**System shell:**
```bash
dagger -c '.help github.com/jpadams/daggerverse/trivy@v0.5.0'
```

**Dagger CLI:**
```bash
dagger -m github.com/jpadams/daggerverse/trivy@v0.5.0 call --help
```

### Get function argument help

List all the optional and required arguments for a Dagger Function using context-sensitive help:

**System shell:**
```bash
dagger -c 'github.com/jpadams/daggerverse/trivy@v0.5.0 | scan-image | .help'
```

**Dagger CLI:**
```bash
dagger -m github.com/jpadams/daggerverse/trivy@v0.5.0 call scan-image --help
```
