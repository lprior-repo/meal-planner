---
id: ops/getting-started/types-env
title: "Env"
category: ops
tags: ["ops", "file", "directory", "module", "container"]
---

# Env

> **Context**: The `Env` type represents an environment consisting of inputs and desired outputs, for use by an `LLM`. For example, an environment might provide a `D...


The `Env` type represents an environment consisting of inputs and desired outputs, for use by an `LLM`. For example, an environment might provide a `Directory`, a `Container`, a custom module, and a string variable as inputs, and request a `Container` as output.

## Common operations

| Field | Description |
|-------|-------------|
| `input` | Retrieves an input value by name |
| `inputs` | Retrieves all input values |
| `output` | Retrieves an output value by name |
| `outputs` | Retrieves all output values |
| `withContainerInput` | Creates or updates an input of type `Container` |
| `withContainerOutput` | Declare a desired output of type `Container` |
| `withDirectoryInput` | Creates or updates an input of type `Directory` |
| `withDirectoryOutput` | Declare a desired output of type `Directory` |
| `withFileInput` | Creates or updates an input of type `File` |
| `withFileOutput` | Declare a desired output of type `File` |
| `with[Object]Input` | Creates or updates an input of type `Object` |
| `with[Object]Output` | Declare a desired output of type `Object` |

## Examples

### Use string inputs and outputs

**Go:**
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

**Example:**
```bash
dagger call agent --question="what is an ion?"
```

### Use container inputs and outputs

**Go:**
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

**Example:**
```bash
dagger call agent terminal
```

### Use directory inputs and outputs

**Go:**
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

**Example:**
```bash
dagger call agent export --path=/tmp/out
```

### Combine inputs and outputs of multiple types

**Go:**
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

**Example:**
```bash
dagger call agent export --path=/tmp/out/myfile
```

## See Also

- [Documentation Overview](./COMPASS.md)
