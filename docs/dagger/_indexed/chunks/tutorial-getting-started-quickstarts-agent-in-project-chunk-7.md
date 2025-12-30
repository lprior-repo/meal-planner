---
doc_id: tutorial/getting-started/quickstarts-agent-in-project
chunk_id: tutorial/getting-started/quickstarts-agent-in-project#chunk-7
heading_path: ["quickstarts-agent-in-project", "Run the agent"]
chunk_type: mixed
tokens: 84
summary: "Type `dagger` to launch Dagger Shell in interactive mode."
---
Type `dagger` to launch Dagger Shell in interactive mode.

Check the help text for the new Dagger Function:

```
.help develop
```

Make sure your LLM has been properly configured:

```
llm | model
```

Call the agent with an assignment:

```
develop "make the main page blue"
```

Since the agent returns a `Directory`, use Dagger Shell to do more with that `Directory`:

```bash
