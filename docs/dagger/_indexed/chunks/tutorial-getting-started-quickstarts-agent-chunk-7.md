---
doc_id: tutorial/getting-started/quickstarts-agent
chunk_id: tutorial/getting-started/quickstarts-agent#chunk-7
heading_path: ["quickstarts-agent", "Run the agent"]
chunk_type: mixed
tokens: 150
summary: "Dagger Shell is the fastest way to interact with the Dagger API."
---
Dagger Shell is the fastest way to interact with the Dagger API. Type `dagger` to launch Dagger Shell in interactive mode.

Check the help text for the new Dagger Function:

```
.help go-program
```

Make sure your LLM provider has been properly configured:

```
llm | model
```

Call the Dagger Function with an assignment:

```
go-program "write a curl clone"
```

You'll see the agent receive the prompt, write code, validate it, and return a `Container` with the result.

Once the agent has successfully returned a `Container`, open an interactive terminal in the container:

```
go-program "write a curl clone" | terminal
```

Run the program and confirm that it works:

```bash
> ls
