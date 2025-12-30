---
doc_id: ops/cookbook/agents
chunk_id: ops/cookbook/agents#chunk-4
heading_path: ["agents", "Use directory inputs and outputs"]
chunk_type: code
tokens: 692
summary: "The following Dagger Function creates an environment with a directory input and a directory output."
---
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
