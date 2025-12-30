---
doc_id: tutorial/features/llm
chunk_id: tutorial/features/llm#chunk-4
heading_path: ["llm", "Prompt mode"]
chunk_type: code
tokens: 138
summary: "Dagger Shell lets you interact with the attached LLM using natural language commands."
---
Dagger Shell lets you interact with the attached LLM using natural language commands. Each input builds upon previous interactions, creating a prompt chain that lets you execute complex workflows without needing to know the exact syntax of the underlying Dagger API.

"Prompt mode" can be accessed at any time in the Dagger Shell by typing `>`. Here's an example:

```bash
source=$(container | from node | with-mounted-directory /src https://github.com/dagger/hello-dagger | with-workdir /src)
>You have a container with source code in /src. Describe the source code.
>Does the application have unit tests?
>Find all the unit tests. Deduce what the application does. Describe it in one paragraph.
```
