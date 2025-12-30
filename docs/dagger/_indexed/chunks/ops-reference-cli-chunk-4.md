---
doc_id: ops/reference/cli
chunk_id: ops/reference/cli#chunk-4
heading_path: ["cli", "Implement a standalone module in Go"]
chunk_type: code
tokens: 226
summary: "dagger init --sdk=go
```



Prepare a local module for development."
---
dagger init --sdk=go
```

### dagger develop

Prepare a local module for development.

```
dagger develop [options]
```

### dagger install

Install a dependency.

```
dagger install [options] <module>
```

**Example:**
```bash
dagger install github.com/shykes/daggerverse/hello@v0.3.0
```

### dagger functions

List available functions in a module.

```
dagger functions [options] [function]...
```

### dagger query

Send API queries to a dagger engine.

```
dagger query [options] [operation]
```

**Example:**
```bash
dagger query <<EOF
{
  container {
    from(address:"hello-world") {
      withExec(args:["/hello"]) {
        stdout
      }
    }
  }
}
EOF
```

### dagger run

Run a command in a Dagger session.

```
dagger run [options] <command>...
```

**Examples:**
```bash
dagger run go run main.go
dagger run node index.mjs
dagger run python main.py
```

### dagger login / logout

Log in to or out of Dagger Cloud.

```
dagger login [org]
dagger logout
```

### dagger config

Get or set module configuration.

```
dagger config [options]
```

### dagger update

Update a module's dependencies.

```
dagger update [options] [<DEPENDENCY>...]
```

### dagger version

Print dagger version.

```
dagger version
```
