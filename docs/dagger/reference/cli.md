# CLI Reference

A tool to run composable workflows in containers.

## Main Commands

### dagger

```
dagger [options] [subcommand | file...]
```

**Options:**
- `--allow-llm strings` - List of URLs of remote modules allowed to access LLM APIs
- `-y, --auto-apply` - Automatically apply changes when a changeset is returned
- `-c, --command string` - Execute a dagger shell command
- `-d, --debug` - Show debug logs and full verbosity
- `-i, --interactive` - Spawn a terminal on container exec failure
- `-m, --mod string` - Module reference to load
- `--model string` - LLM model to use
- `-E, --no-exit` - Leave the TUI running after completion
- `--progress string` - Progress output format (auto, plain, tty, dots)
- `-q, --quiet` - Reduce verbosity
- `-s, --silent` - Do not show progress at all
- `-v, --verbose` - Increase verbosity
- `-w, --web` - Open trace URL in a web browser

### dagger call

Call one or more functions, interconnected into a pipeline.

```
dagger call [options]
```

**Options:**
- `-j, --json` - Present result as JSON
- `-m, --mod string` - Module reference to load
- `-o, --output string` - Save the result to a local file or directory

### dagger init

Initialize a new module.

```
dagger init [options] [path]
```

**Examples:**
```bash
# Reference a remote module as blueprint
dagger init --blueprint=github.com/example/blueprint

# Implement a standalone module in Go
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
