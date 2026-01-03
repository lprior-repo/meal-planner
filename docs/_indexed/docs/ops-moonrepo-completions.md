---
id: ops/moonrepo/completions
title: "completions"
category: ops
tags: ["completions", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>completions</title>
  <description>The `moon completions` command will generate moon command and argument completions for your current shell. This command will write to stdout, which can then be redirected to a file of your choice.</description>
  <created_at>2026-01-02T19:55:26.906981</created_at>
  <updated_at>2026-01-02T19:55:26.906981</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Options" level="3"/>
    <section name="Examples" level="3"/>
    <section name="Bash" level="4"/>
    <section name="Fish" level="4"/>
    <section name="Zsh" level="4"/>
  </sections>
  <features>
    <feature>bash</feature>
    <feature>examples</feature>
    <feature>fish</feature>
    <feature>options</feature>
  </features>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>completions,operations,moonrepo</tags>
</doc_metadata>
-->

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
