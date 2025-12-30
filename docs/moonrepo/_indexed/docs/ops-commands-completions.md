---
id: ops/commands/completions
title: "completions"
category: ops
tags: ["commands", "completions", "operations"]
---

# completions

> **Context**: The `moon completions` command will generate moon command and argument completions for your current shell. This command will write to stdout, which ca

The `moon completions` command will generate moon command and argument completions for your current shell. This command will write to stdout, which can then be redirected to a file of your choice.

```
$ moon completions > ./path/to/write/to
```

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

## Reload shell (or restart terminal)
omz reload
```


## See Also

- [Documentation Index](./COMPASS.md)
