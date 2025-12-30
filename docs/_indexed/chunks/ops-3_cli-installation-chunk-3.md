---
doc_id: ops/3_cli/installation
chunk_id: ops/3_cli/installation#chunk-3
heading_path: ["Installation", "Completion"]
chunk_type: code
tokens: 105
summary: "Completion"
---

## Completion

The CLI comes with built-in completions for various shells. Use the following instructions to enable completions for your preferred shell.

### Bash

To enable bash completions, add the following line to your ~/.bashrc:

```bash
source <(wmill completions bash)
```

### Zsh

To enable zsh completions, add the following line to your ~/.zshrc:

```bash
source <(wmill completions zsh)
```

### Fish

To enable fish completions, add the following line to your ~/.config/fish/config.fish:

```bash
source (wmill completions fish | psub)
```
