---
doc_id: ops/cookbook/agents
chunk_id: ops/cookbook/agents#chunk-2
heading_path: ["agents", "Use string inputs and outputs"]
chunk_type: code
tokens: 437
summary: "The following Dagger Function creates an environment with a string input and a string output."
---
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
