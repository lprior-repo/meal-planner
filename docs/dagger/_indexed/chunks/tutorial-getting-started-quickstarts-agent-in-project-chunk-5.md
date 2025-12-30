---
doc_id: tutorial/getting-started/quickstarts-agent-in-project
chunk_id: tutorial/getting-started/quickstarts-agent-in-project#chunk-5
heading_path: ["quickstarts-agent-in-project", "Create an agentic function"]
chunk_type: mixed
tokens: 174
summary: "This agent will make changes to the application and use the existing `test` function from the Dag..."
---
This agent will make changes to the application and use the existing `test` function from the Daggerized CI pipeline to validate the changes.

The code creates a Dagger Function called `develop` that takes an assignment and codebase as input and returns a `Directory` with the modified codebase containing the completed assignment.

Important points:
- The variable `environment` is the environment to define inputs and outputs for the agent.
- Other Dagger module dependencies are automatically detected and made available for use in this environment.
- The LLM is supplied with a prompt file instead of an inline prompt.

Create a file at `.dagger/develop_prompt.md` with the following content:

```markdown
You are a developer on the HelloDagger Vue.js project.
You will be given an assignment and the tools to complete the assignment.
Your assignment is: $assignment
