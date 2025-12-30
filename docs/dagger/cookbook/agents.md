# LLMs and Environments

This page contains practical examples for working with LLMs and environments in Dagger. Each section below provides code examples in multiple languages and demonstrates different approaches.

## Use string inputs and outputs

The following Dagger Function creates an environment with a string input and a string output. The input is a question, and the output represents the answer. The environment is given to an LLM with a prompt describing how it should complete its work.

### Go

```go
package main

import (
	"context"
)

type MyModule struct{}

func (m *MyModule) Agent(
	ctx context.Context,
	question string,
) (string, error) {
	environment := dag.Env().
		WithStringInput("question", question, "the question").
		WithStringOutput("answer", "the answer to the question")

	work := dag.LLM().
		WithEnv(environment).
		WithPrompt(`
			You are an assistant that helps with complex questions.
			You will receive a question and you need to provide a detailed answer.
			Make sure to use the provided context and environment variables.
			Your answer should be clear and concise.
			Your question is: $question
			`)

	return work.
		Env().
		Output("answer").
		AsString(ctx)
}
```

### Python

```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def agent(self, question: str) -> str:
        environment = (
            dag.env()
            .with_string_input("question", question, "the question")
            .with_string_output("answer", "the answer to the question")
        )

        work = (
            dag.llm()
            .with_env(environment)
            .with_prompt(
                """
                You are an assistant that helps with complex questions.
                You will receive a question and you need to provide a detailed answer.
                Make sure to use the provided context and environment variables.
                Your answer should be clear and concise.
                Your question is: $question
                """
            )
        )

        return await work.env().output("answer").as_string()
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
export class MyModule {
  @func()
  async agent(question: string): Promise<string> {
    const environment = dag
      .env()
      .withStringInput("question", question, "the question")
      .withStringOutput("answer", "the answer to the question")

    const work = dag
      .llm()
      .withEnv(environment)
      .withPrompt(
        `You are an assistant that helps with complex questions.
        You will receive a question and you need to provide a detailed answer.
        Make sure to use the provided context and environment variables.
        Your answer should be clear and concise.
        Your question is: $question`,
      )

    return await work.env().output("answer").asString()
  }
}
```

### Example

Ask a question:

```bash
dagger call agent --question="what is an ion?"
```

## Use container inputs and outputs

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

## Use directory inputs and outputs

The following Dagger Function creates an environment with a directory input and a directory output. The input is a directory containing various files, and the output is a different directory containing translations of the original files. The environment is given to an LLM with a prompt describing how it should complete its work.

### Go

```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Agent() *dagger.Directory {
	dir := dag.Git("github.com/dagger/dagger").Branch("main").Tree()

	environment := dag.Env().
		WithDirectoryInput("source", dir, "the source directory to use").
		WithDirectoryOutput("result", "the updated directory")

	work := dag.LLM().
		WithEnv(environment).
		WithPrompt(`
			You have access to a directory containing various files.
			Translate only the README file in the directory to French and Spanish.
			Ensure that the translations are accurate and maintain the original formatting.
			Do not modify any other files in the directory.
			Create a sub-directory named 'translations' to store the translated files.
			For French, add an 'fr' suffix to the translated file name.
			For Spanish, add an 'es' suffix to the translated file name.
			Do not create any other new files or directories.
			Do not delete any files or directories.
			Do not investigate any sub-directories.
			Once complete, return the 'translations' directory.
			`)

	return work.
		Env().
		Output("result").
		AsDirectory()
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def agent(self) -> dagger.Directory:
        dirname = dag.git("github.com/dagger/dagger").branch("main").tree()

        environment = (
            dag.env()
            .with_directory_input("source", dirname, "the source directory to use")
            .with_directory_output("result", "the updated directory")
        )

        work = (
            dag.llm()
            .with_env(environment)
            .with_prompt(
                """
                You have access to a directory containing various files.
                Translate only the README file in the directory to French and Spanish.
                Ensure that the translations are accurate and maintain the original
                formatting.
                Do not modify any other files in the directory.
                Create a subdirectory named translations to store the translated files.
                For French, add an 'fr' suffix to the translated file name.
                For Spanish, add an 'es' suffix to the translated file name.
                Do not create any other new files or directories.
                Do not delete any files or directories.
                Do not investigate any sub-directories.
                Once complete, return the 'translations' directory.
                """
            )
        )

        return work.env().output("result").as_directory()
```

### TypeScript

```typescript
import { dag, object, func, Directory } from "@dagger.io/dagger"

@object()
export class MyModule {
  @func()
  agent(): Directory {
    const dir = dag.git("github.com/dagger/dagger").branch("main").tree()

    const environment = dag
      .env()
      .withDirectoryInput("source", dir, "the source directory to use")
      .withDirectoryOutput("result", "the updated directory")

    const work = dag
      .llm()
      .withEnv(environment)
      .withPrompt(
        `You have access to a directory containing various files.
        Translate only the README file in the directory to French and Spanish.
        Ensure that the translations are accurate and maintain the original formatting.
        Do not modify any other files in the directory.
        Create a sub-directory named 'translations' to store the translated files.
        For French, add an 'fr' suffix to the translated file name.
        For Spanish, add an 'es' suffix to the translated file name.
        Do not create any other new files or directories.
        Do not delete any files or directories.
        Do not investigate any sub-directories.
        Once complete, return the 'translations' directory.
        `,
      )

    return work.env().output("result").asDirectory()
  }
}
```

### Example

Have the agent create the translations and export the directory of translated files to the host:

```bash
dagger call agent export --path=/tmp/out
```

## Combine inputs and outputs of multiple types

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

## Build a Golang coding agent

The following Dagger Function creates a Golang coding agent. The input is a programming assignment and the output is a Go executable satisfying the assignment. The environment consists of a base `golang` container, which is given to an LLM with a prompt describing how it should perform the work.

### Go

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

### Python

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

### TypeScript

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

### Example

Have the agent update the container and open an interactive terminal to inspect the container filesystem:

```bash
dagger call agent terminal
```
