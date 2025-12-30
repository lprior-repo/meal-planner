---
doc_id: ops/features/shell
chunk_id: ops/features/shell#chunk-3
heading_path: ["shell", "Input modes"]
chunk_type: code
tokens: 90
summary: "Dagger Shell supports multiple ways to input commands:

- Inline execution
- Standard input
- Scr..."
---
Dagger Shell supports multiple ways to input commands:

- Inline execution
- Standard input
- Script
- Interactive REPL

```bash
dagger -c 'container | from alpine | terminal'
```

```bash
dagger <<EOF
container | from alpine | terminal
EOF
```

```bash
#!/usr/bin/env dagger
container |
from alpine |
with-exec cat /etc/os-release |
stdout
```

Interactive mode (type 'dagger' for interactive mode):
```bash
container | from alpine | terminal
```
