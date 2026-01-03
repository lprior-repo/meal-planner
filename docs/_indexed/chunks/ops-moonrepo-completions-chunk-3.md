---
doc_id: ops/moonrepo/completions
chunk_id: ops/moonrepo/completions#chunk-3
heading_path: ["completions", "In your profile"]
chunk_type: code
tokens: 55
summary: "In your profile"
---

## In your profile
source ~/.bash_completions/moon.sh
```

### Fish

Write the file to Fish's completions directory.

```
mkdir -p ~/.config/fish/completions
moon completions > ~/.config/fish/completions/moon.fish
```

#### Zsh

If using [oh-my-zsh](https://ohmyz.sh/) (the `_` prefix is required).

```
mkdir -p ~/.oh-my-zsh/completions
moon completions > ~/.oh-my-zsh/completions/_moon
