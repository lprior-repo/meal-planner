---
doc_id: tutorial/features/llm
chunk_id: tutorial/features/llm#chunk-2
heading_path: ["llm", "Tool use"]
chunk_type: code
tokens: 543
summary: "A key feature of Dagger's LLM integration is out-of-the-box support for tool use using Dagger Fun..."
---
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
