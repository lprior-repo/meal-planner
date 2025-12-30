# LLM Integration

Dagger's `LLM` type includes API methods to attach objects to a Large Language Model (LLM), send prompts, and receive responses.

## Prompts

Use the `LLM.withPrompt()` API method to append prompts to the LLM context:

**System shell:**
```bash
dagger <<EOF
llm |
  with-prompt "What tools do you have available?"
EOF
```

**Dagger Shell:**
```
llm |
  with-prompt "What tools do you have available?"
```

For longer or more complex prompts, use the `LLM.withPromptFile()` API method to read the prompt from a text file:

**System shell:**
```bash
dagger <<EOF
llm |
  with-prompt-file ./prompt.txt
EOF
```

**Dagger Shell:**
```
llm |
  with-prompt-file ./prompt.txt
```

## Responses and Variables

Use the `LLM.lastReply()` API method to obtain the last reply from the LLM, or the `LLM.history()` API method to get the complete message history.

> **Important:** Most LLM services impose rate limits (restrictions on the number of requests they will accept within a given time period). Dagger handles this gracefully with built-in rate limit detection and automatic retry with exponential backoff.

Dagger supports the use of variables in prompts. This allows you to interpolate results of other operations into an LLM prompt:

**System shell:**
```bash
dagger <<EOF
source=\$(container |
  from alpine |
  with-directory /src https://github.com/dagger/dagger |
  directory /src)

environment=\$(env |
  with-directory-input 'source' \$source 'a directory with source code')

llm |
  with-env \$environment |
  with-prompt "The directory also has some tools available." |
  with-prompt "Use the tools in the directory to read the first paragraph of the README.md file in the directory." |
  with-prompt "Reply with only the selected text." |
  last-reply
EOF
```

**Dagger Shell:**
```
source=$(container |
  from alpine |
  with-directory /src https://github.com/dagger/dagger |
  directory /src)

environment=$(env |
  with-directory-input 'source' $source 'a directory with source code')

llm |
  with-env $environment |
  with-prompt "The directory also has some tools available." |
  with-prompt "Use the tools in the directory to read the first paragraph of the README.md file in the directory." |
  with-prompt "Reply with only the selected text." |
  last-reply
```

## Environments

Dagger [modules](/features/reusability) are collections of Dagger Functions. When you give a Dagger module to the `LLM` type, every Dagger Function is turned into a tool that the LLM can call.

Environments configure any number of inputs and outputs for the LLM. For example, an environment might provide a `Directory`, a `Container`, a custom module, and a `string` variable. The LLM can use the scalars and the functions of these objects to complete the assigned task.

The documentation for the modules are provided to the LLM, so make sure to provide helpful documentation in your Dagger Functions. The LLM should be able to figure out how to use the tools on its own. Don't worry about describing the objects too much in your prompts because it will be redundant with this automatic documentation.

Consider the following Dagger Function:

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

**PHP:**
```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\DaggerFunction;
use Dagger\Attribute\DaggerObject;
use Dagger\Attribute\Doc;
use Dagger\Container;

use function Dagger\dag;

#[DaggerObject]
#[Doc('A generated module for CodingAgent functions')]
class CodingAgent
{
    #[DaggerFunction]
    #[Doc('Write a Go program')]
    public function goProgram(string $assignment): Container
    {
        $environment = dag()->env()
            ->withStringInput('assignment', $assignment, 'the assignment to complete')
            ->withContainerInput('builder', dag()->container()->from('golang')->withWorkdir('/app'), 'a container to use for building Go code')
            ->withContainerOutput('completed', 'the completed assignment in the Golang container');

        return dag()
            ->llm()
            ->withEnv($environment)
            ->withPrompt('
                You are an expert Go programmer with an assignment to create a Go program
                Create files in the default directory in $builder
                Always build the code to make sure it is valid
                Do not stop until your assignment is completed and the code builds
                Your assignment is: $assignment')
            ->env()
            ->output('completed')
            ->asContainer();
    }
}
```

**Java:**
```java
package io.dagger.modules.codingagent;

import static io.dagger.client.Dagger.dag;

import io.dagger.client.Container;
import io.dagger.client.Env;
import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;

/** CodingAgent main object */
@Object
public class CodingAgent {
  /** Write a Go program */
  @Function
  public Container goProgram(String assignment) {
    Env environment = dag().env()
        .withStringInput("assignment", assignment, "the assignment to complete")
        .withContainerInput("builder", dag().container().from("golang").withWorkdir("/app"), "a container to use for building Go code")
        .withContainerOutput("completed", "the completed assignment in the Golang container");

    return dag()
      .llm()
      .withEnv(environment)
      .withPrompt("""
        You are an expert Go programmer with an assignment to create a Go program
        Create files in the default directory in $builder
        Always build the code to make sure it is valid
        Do not stop until your assignment is completed and the code builds
        Your assignment is: $assignment
        """)
      .env()
      .output("completed")
      .asContainer();
  }
}
```

Here, an instance a `Container` is attached as an input to the `Env` environment. The `Container` is a type with a number of functions useful for a coding environment such as `WithNewFile()`, `File().Contents()`, and `WithExec()`. When this environment is attached to an `LLM`, the LLM can call any of these Dagger Functions to change the state of the `Container` and complete the assigned task.

In the `Env`, a `Container` instance called `completed` is specified as a desired output of the LLM. This means that the LLM should return the `Container` instance as a result of completing its task. The resulting `Container` object is then available for further processing or for use in other Dagger Functions.
