---
doc_id: ops/commands/completions
chunk_id: ops/commands/completions#chunk-2
heading_path: ["completions", "Options"]
chunk_type: code
tokens: 62
summary: "Options"
---

## Options

-   `--shell` - Shell to explicitly generate for.

### Examples

#### Bash

If using [bash-completion](https://github.com/scop/bash-completion).

```
mkdir -p ~/.bash_completion.d
moon completions > ~/.bash_completion.d/moon.sh
```

Otherwise write the file to a common location, and source it in your profile.

```
mkdir -p ~/.bash_completions
moon completions > ~/.bash_completions/moon.sh
