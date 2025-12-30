---
doc_id: ops/getting-started/types-env
chunk_id: ops/getting-started/types-env#chunk-3
heading_path: ["types-env", "Examples"]
chunk_type: code
tokens: 619
summary: "**Go:**
```go
package main

import (
	\"context\"
)

type MyModule struct{}

func (m *MyModule) Age..."
---
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
