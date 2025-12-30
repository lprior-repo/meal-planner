# LLM

The `LLM` type initializes a Large Language Model (LLM).

> **ENV TYPE:** You use an `LLM` in conjunction with `Env`. The `Env` type is used to represent the environment in which an LLM operates. It allows the LLM to interact with inputs and outputs, such as directories, containers, and custom modules.

## Common operations

| Field | Description |
|-------|-------------|
| `model` | Returns the model used by the LLM |
| `lastReply` | Returns the last reply from the LLM |
| `history` | Returns the LLM message history |
| `withEnv` | Allows the LLM to interact with an environment |
| `withPrompt` | Appends a prompt to the LLM context |
| `withPromptFile` | Appends a prompt file to the LLM context |
| `withPromptVar` | Adds a string variable to the LLM context |
| `withModel` | Sets the model used by the LLM |

## Examples

### Build a Golang coding agent

The following Dagger Function creates a Golang coding agent. The input is a programming assignment and the output is a Go executable satisfying the assignment.

**Go:**
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

**Python:**
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

**TypeScript:**
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

**Example:**

Have the agent update the container and open an interactive terminal:

```bash
dagger call agent terminal
```
