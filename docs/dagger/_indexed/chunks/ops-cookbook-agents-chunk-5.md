---
doc_id: ops/cookbook/agents
chunk_id: ops/cookbook/agents#chunk-5
heading_path: ["agents", "Combine inputs and outputs of multiple types"]
chunk_type: code
tokens: 485
summary: "The following Dagger Function creates an environment with two inputs (a container and a directory..."
---
The following Dagger Function creates an environment with two inputs (a container and a directory) and one output (a file). The input container is a base `golang` container, the input directory is a Git repository containing Golang source code, and the output is the built Go executable. The environment is given to an LLM with a prompt describing how it should work.

### Go

```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Agent() *dagger.File {
	dir := dag.Git("github.com/golang/example").Branch("master").Tree().Directory("/hello")
	builder := dag.Container().From("golang:latest")

	environment := dag.Env().
		WithContainerInput("container", builder, "a Golang container").
		WithDirectoryInput("directory", dir, "a directory with source code").
		WithFileOutput("file", "the built Go executable")

	work := dag.LLM().
		WithEnv(environment).
		WithPrompt(`
			You have access to a Golang container.
			You also have access to a directory containing Go source code.
			Mount the directory into the container and build the Go application.
			Once complete, return only the built binary.
			`)

	return work.
		Env().
		Output("file").
		AsFile()
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def agent(self) -> dagger.File:
        dirname = dag.git("github.com/golang/example").branch("master").tree()
        builder = dag.container().from_("golang:latest")

        environment = (
            dag.env()
            .with_container_input("container", builder, "a Golang container")
            .with_directory_input("directory", dirname, "a directory with source code")
            .with_file_output("file", "the built Go executable")
        )

        work = (
            dag.llm()
            .with_env(environment)
            .with_prompt(
                """
                You have access to a Golang container.
                You also have access to a directory containing Go source code.
                Mount the directory into the container and build the Go application.
                Once complete, return only the built binary.
                """
            )
        )

        return work.env().output("file").as_file()
```

### TypeScript

```typescript
import { dag, object, func, File } from "@dagger.io/dagger"

@object()
export class MyModule {
  @func()
  agent(): File {
    const dir = dag.git("github.com/golang/example").branch("master").tree()
    const builder = dag.container().from("golang:latest")

    const environment = dag
      .env()
      .withContainerInput("container", builder, "a Golang container")
      .withDirectoryInput("directory", dir, "a directory with source code")
      .withFileOutput("file", "the built Go executable")

    const work = dag
      .llm()
      .withEnv(environment)
      .withPrompt(
        `You have access to a Golang container.
        You also have access to a directory containing Go source code.
        Mount the directory into the container and build the Go application.
        Once complete, return only the built binary.`,
      )

    return work.env().output("file").asFile()
  }
}
```

### Example

Have the agent build the Go executable and export it to the host:

```bash
dagger call agent export --path=/tmp/out/myfile
```
