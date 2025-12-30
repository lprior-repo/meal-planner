---
doc_id: ops/reference/cli
chunk_id: ops/reference/cli#chunk-2
heading_path: ["cli", "Main Commands"]
chunk_type: mixed
tokens: 264
summary: "```
dagger [options] [subcommand | file."
---
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
