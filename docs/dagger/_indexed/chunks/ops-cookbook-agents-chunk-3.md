---
doc_id: ops/cookbook/agents
chunk_id: ops/cookbook/agents#chunk-3
heading_path: ["agents", "Use container inputs and outputs"]
chunk_type: code
tokens: 450
summary: "The following Dagger Function creates an environment with a container input and a container output."
---
The following Dagger Function creates an environment with a container input and a container output. The input is a base `alpine` container, and the output is the same container, updated with additional libraries and tools. The environment is given to an LLM with a prompt describing how it should update the container.

### Go

```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Agent() *dagger.Container {
	base := dag.Container().From("alpine:latest")

	environment := dag.Env().
		WithContainerInput("base", base, "a base container to use").
		WithContainerOutput("result", "the updated container")

	work := dag.LLM().
		WithEnv(environment).
		WithPrompt(`
			You are a software engineer with deep knowledge of Web application development.
			You have access to a container.
			Install the necessary tools and libraries to create a
			complete development environment for Web applications.
			Once complete, return the updated container.
			`)

	return work.
		Env().
		Output("result").
		AsContainer()
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def agent(self) -> dagger.Container:
        base = dag.container().from_("alpine:latest")

        environment = (
            dag.env()
            .with_container_input("base", base, "a base container to use")
            .with_container_output("result", "the updated container")
        )

        work = (
            dag.llm()
            .with_env(environment)
            .with_prompt(
                """
                You are a software engineer with deep knowledge of Web application
                development.
                You have access to a container.
                Install the necessary tools and libraries to create a
                complete development environment for Web applications.
                Once complete, return the updated container.
                """
            )
        )

        return work.env().output("result").as_container()
```

### TypeScript

```typescript
import { dag, object, func, Container } from "@dagger.io/dagger"

@object()
export class MyModule {
  @func()
  agent(): Container {
    const base = dag.container().from("alpine:latest")

    const environment = dag
      .env()
      .withContainerInput("base", base, "a base container to use")
      .withContainerOutput("result", "the updated container")

    const work = dag
      .llm()
      .withEnv(environment)
      .withPrompt(
        `You are a software engineer with deep knowledge of Web application development.
        You have access to a container.
        Install the necessary tools and libraries to create a
        complete development environment for Web applications.
        Once complete, return the updated container.`,
      )

    return work.env().output("result").asContainer()
  }
}
```

### Example

Have the agent update the container and open an interactive terminal to inspect the container filesystem:

```bash
dagger call agent terminal
```
