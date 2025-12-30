---
id: tutorial/features/llm
title: "LLM Integration"
category: tutorial
tags: ["tutorial", "directory", "module", "function", "container"]
---

# LLM Integration

> **Context**: Dagger can be used as a runtime and programming environment for AI agents. Dagger provides an `LLM` type that enables native integration of Large Lang...


Dagger can be used as a runtime and programming environment for AI agents. Dagger provides an `LLM` type that enables native integration of Large Language Models (LLM) in your workflows.

## Tool use

A key feature of Dagger's LLM integration is out-of-the-box support for tool use using Dagger Functions: an LLM can automatically discover and use any available Dagger Functions in the provided environment.

### Environments

Environments configure any number of inputs and outputs for the LLM. For example, an environment might provide a `Directory`, a `Container`, a custom module, and a `string` variable. The LLM can use these objects and their functions to complete the assigned task.

The documentation for the modules are provided to the LLM via [inline documentation](./concept-extending-documentation.md) in your Dagger Functions. The LLM can then analyze the available tools and select which ones to use.

Here's an example in Dagger Shell:

```bash
base=$(container | from alpine)
env=$(env | with-container-input 'base' $base 'a base container' | with-container-output 'python-dev' 'a container with python dev tools')
llm | with-env $env | with-prompt "You have an alpine container. Install tools to develop with Python." | env | output python-dev | as-container | terminal
```

Here, an instance of a `Container` is attached as an input to the `Env` environment. The `Container` is a core type with a number of useful functions, such as `withNewFile()` and `withExec()`. When this environment is attached to an `LLM`, the LLM can call any of these Dagger Functions to change the state of the `Container` and complete the assigned task.

### Agent loop

Consider the following Dagger Function (Go example):

```go
package main

import (
    "dagger/coding-agent/internal/dagger"
)

type CodingAgent struct{}

// Write a Go program
func (m *CodingAgent) GoProgram(
    // The programming assignment, e.g. "write me a curl clone"
    assignment string,
) *dagger.Container {
    environment := dag.Env().
        WithStringInput("assignment", assignment, "the assignment to complete").
        WithContainerInput("builder",
            dag.Container().From("golang").WithWorkdir("/app"),
            "a container to use for building Go code").
        WithContainerOutput("completed", "the completed assignment in the Golang container")

    work := dag.LLM().
        WithEnv(environment).
        WithPrompt(`
            You are an expert Go programmer with an assignment to create a Go program
            Create files in the default directory in $builder
            Always build the code to make sure it is valid
            Do not stop until your assignment is completed and the code builds
            Your assignment is: $assignment
            `)

    return work.
        Env().
        Output("completed").
        AsContainer()
}
```

This Dagger Function creates a new LLM, gives it an environment (a container with various tools) with an assignment, and prompts it to complete the assignment. The LLM then runs in a loop, calling tools and iterating on its work, until it completes the assignment. This loop happens inside the LLM object, so the value of `result` is the environment with the completed assignment.

## MCP

Model Context Protocol (MCP) support in Dagger can be broken into two categories:

1. Exposing MCP outside Dagger
2. Connecting to external MCP servers from Dagger

### Expose MCP outside Dagger

Dagger has built-in MCP support that allows you to easily expose Dagger modules as an MCP server. This allows you to configure a client (such as Claude Desktop, Cursor, Goose CLI/Desktop) to consume modules from [the Daggerverse](https://daggerverse.dev) or any Git repository as native MCP servers.

> **Warning:** Currently, only Dagger modules with no required constructor arguments are supported when exposing an MCP server outside Dagger.

### Connect to external MCP servers from Dagger

Support for connecting to external MCP servers from Dagger is coming soon.

## Prompt mode

Dagger Shell lets you interact with the attached LLM using natural language commands. Each input builds upon previous interactions, creating a prompt chain that lets you execute complex workflows without needing to know the exact syntax of the underlying Dagger API.

"Prompt mode" can be accessed at any time in the Dagger Shell by typing `>`. Here's an example:

```bash
source=$(container | from node | with-mounted-directory /src https://github.com/dagger/hello-dagger | with-workdir /src)
>You have a container with source code in /src. Describe the source code.
>Does the application have unit tests?
>Find all the unit tests. Deduce what the application does. Describe it in one paragraph.
```

## Supported models

Dagger supports a wide range of popular language models, including those from OpenAI, Anthropic and Google. Dagger can access these models either through their respective cloud-based APIs or using local providers like Docker Model Runner or Ollama.

Dagger uses your system's standard environment variables to route LLM requests. Dagger will look for these variables in your environment, or in a `.env` file in the current directory. Learn more about [configuring LLM endpoints in Dagger](/reference/configuration/llm).

## Observability

Dagger provides [end-to-end tracing](./ops-features-observability.md) of prompts, tool calls, and even low-level system operations. All agent state changes are observable in real time.

## See Also

- [inline documentation](./concept-extending-documentation.md)
- [end-to-end tracing](./ops-features-observability.md)
