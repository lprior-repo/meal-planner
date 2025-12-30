# Build an AI Agent

Agentic workflows need repeatability, modularity, observability and cross-platform support. Dagger provides a way to build reproducible workflows in any language with custom environments, parallel processing, and seamless chaining.

This quickstart will guide you through creating and running your first AI agent with Dagger.

The agent will use an LLM of your choosing to solve a programming assignment. The agent will have access to tools to write code and validate it.

## Requirements

This quickstart will take you approximately 10 minutes to complete. You should be familiar with programming in Go, Python, TypeScript, PHP, or Java.

Before beginning, ensure that:

- you have [installed the Dagger CLI](/getting-started/installation).
- you know [the basics of Dagger](/getting-started/quickstarts/basics).
- you have a container runtime installed on your system and running. This can be Docker, Podman, nerdctl, Apple Container, or other Docker-like systems.
- you have a GitHub account (optional, only if configuring Dagger Cloud)

> **Tip:** Dagger SDKs generate native code-bindings for all dependencies from the Dagger API. If you're using an IDE, this gives you automatic type-checking, code completion and other key features when developing Dagger Functions. Setting up your IDE to work with Dagger is a highly recommended step.

## Configure the LLM endpoint

Follow the LLM endpoint configuration instructions to configure an LLM for use with Dagger.

> **Info:** Use environment variables or a `.env` file. For example: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`

## Configure Dagger Cloud (optional)

> **Important:** This step is optional and will create a Dagger Cloud account, which is free of charge for a single user.

Dagger Cloud is an online visualization tool for Dagger workflows. Create a new Dagger Cloud account by running `dagger login`:

```bash
dagger login
```

## Initialize a Dagger module

In an empty directory, create a new Dagger module:

**Go:**
```bash
dagger init --sdk=go --name=coding-agent
```

**Python:**
```bash
dagger init --sdk=python --name=coding-agent
```

**TypeScript:**
```bash
dagger init --sdk=typescript --name=coding-agent
```

To see the generated Dagger Functions, run:

```bash
dagger functions
```

## Create the agent

Replace the generated Dagger module files as described below.

**Go (`main.go`):**
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

**Python (`src/coding_agent/main.py`):**
```python
import dagger
from dagger import dag, function, object_type

@object_type
class CodingAgent:
    @function
    def go_program(
        self,
        assignment: str,
    ) -> dagger.Container:
        """Write a Go program"""
        environment = (
            dag.env()
            .with_string_input("assignment", assignment, "the assignment to complete")
            .with_container_input(
                "builder",
                dag.container().from_("golang").with_workdir("/app"),
                "a container to use for building Go code",
            )
            .with_container_output(
                "completed", "the completed assignment in the Golang container"
            )
        )
        work = (
            dag.llm()
            .with_env(environment)
            .with_prompt(
                """
                You are an expert Go programmer
                with an assignment to create a Go program
                Create files in the default directory in $builder
                Always build the code to make sure it is valid
                Do not stop until your assignment is completed and the code builds
                Your assignment is: $assignment"""
            )
        )
        return work.env().output("completed").as_container()
```

**TypeScript (`src/index.ts`):**
```typescript
import { dag, object, func, Container } from "@dagger.io/dagger"

@object()
export class CodingAgent {
  /**
   * Write a Go program
   */
  @func()
  goProgram(
    /**
     * The programming assignment, e.g. "write me a curl clone"
     */
    assignment: string,
  ): Container {
    const environment = dag
      .env()
      .withStringInput("assignment", assignment, "the assignment to complete")
      .withContainerInput(
        "builder",
        dag.container().from("golang").withWorkdir("/app"),
        "a container to use for building Go code",
      )
      .withContainerOutput(
        "completed",
        "the completed assignment in the Golang container",
      )

    const work = dag
      .llm()
      .withEnv(environment)
      .withPrompt(
        `You are an expert Go programmer with an assignment to create a Go program
        Create files in the default directory in $builder
        Always build the code to make sure it is valid
        Do not stop until your assignment is completed and the code builds
        Your assignment is: $assignment`,
      )

    return work.env().output("completed").asContainer()
  }
}
```

This code creates a Dagger Function called `go-program` that takes an assignment as input and returns a `Container` with the result of the assignment.

- The variable `environment` is the environment to define inputs and outputs for the agent.
- The input `builder` is a `Container`. This provides a workspace for the agent to create files and execute commands like `go build`.
- The output `completed` signals the agent that it should return a `Container` representing the completed assignment
- When the LLM decides it is finished, the `completed` container is selected from the `Env` outputs and returned.

> **Tip:** Learn more about [agent environments](/getting-started/types/env).

## Run the agent

Dagger Shell is the fastest way to interact with the Dagger API. Type `dagger` to launch Dagger Shell in interactive mode.

Check the help text for the new Dagger Function:

```
.help go-program
```

Make sure your LLM provider has been properly configured:

```
llm | model
```

Call the Dagger Function with an assignment:

```
go-program "write a curl clone"
```

You'll see the agent receive the prompt, write code, validate it, and return a `Container` with the result.

Once the agent has successfully returned a `Container`, open an interactive terminal in the container:

```
go-program "write a curl clone" | terminal
```

Run the program and confirm that it works:

```bash
> ls
# should see a main.go and a go.mod, maybe other files
> go run main.go https://example.com
```

## Next steps

Congratulations! You've created your first AI coding agent. You can now use this agent to solve coding prompts using an LLM.

Now that you've grasped the basics of building an agent, look at our agentic workflow examples for more examples and ideas for your next agent.
