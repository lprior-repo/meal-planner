---
id: tutorial/getting-started/quickstarts-agent-in-project
title: "Add an AI agent to an Existing Project"
category: tutorial
tags: ["tutorial", "ci", "module", "function", "container"]
---

# Add an AI agent to an Existing Project

> **Context**: Now that you've learned the basics of creating an AI agent with Dagger in Build an AI agent, its time to apply those lessons to a more realistic use c...


Now that you've learned the basics of creating an AI agent with Dagger in Build an AI agent, its time to apply those lessons to a more realistic use case. In this guide, you will build an AI agent that builds features for an existing project.

For this guide you will start with a Daggerized project. The agent will use the Dagger functions in this project that are already used locally and in CI for testing the project.

## Requirements

This quickstart will take you approximately 10 minutes to complete. You should ideally have completed the AI agent and CI quickstarts and should be familiar with programming in Go, Python, TypeScript, PHP, or Java.

Before beginning, ensure that:

- you have [installed the Dagger CLI](./ops-getting-started-installation.md).
- you have a container runtime installed on your system and running.
- you have configured an LLM provider to use with Dagger.
- you have a GitHub account
- you have completed the [AI agent quickstart](/getting-started/quickstarts/agent)
- you have completed the [CI quickstart](/getting-started/quickstarts/ci)

## Inspect the example application

This quickstart uses the Daggerized project from the CI quickstart. To verify that your project is in the correct state, change to the project's working directory and list the available Dagger Functions:

```bash
cd hello-dagger
dagger functions
```

This should show:

```
Name        Description
build       Build the application container
build-env   Build a ready-to-use development environment
publish     Publish the application container after building and testing it on-the-fly
test        Return the result of running unit tests
```

## Create a workspace for the agent

The goal of this quickstart is to create an agent to interact with the existing codebase and add features to it. This means that the agent needs the ability to list, read and write files in the project directory.

To give the agent these tools, create a Dagger submodule called `workspace`. This module will have Dagger Functions to list, read, and write files.

Start by creating the submodule:

**Go:**
```bash
dagger init --sdk=go .dagger/workspace
```

**Python:**
```bash
dagger init --sdk=python .dagger/workspace
```

**TypeScript:**
```bash
dagger init --sdk=typescript .dagger/workspace
```

In this Dagger module, each Dagger Function performs a different operation:

- The `read-file` Dagger Function reads a file in the workspace.
- The `write-file` Dagger Function writes a file to the workspace.
- The `list-files` Dagger Function lists all the files in the workspace.
- The `test` Dagger Function runs the tests on the files in the workspace.

See the functions of the new workspace module:

```bash
dagger -m .dagger/workspace functions
```

Now install the new submodule as a dependency to the main module:

```bash
dagger install ./.dagger/workspace
```

## Create an agentic function

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

## Constraints
- Before writing code, analyze the Workspace to understand the project.
- Do not make unneccessary changes.
- Always run tests to validate your code changes.
- Do not stop until you have completed the assignment and the tests pass.
```

To see the new function, run:

```bash
dagger functions
```

## Run the agent

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
## Save the directory containing the completed assignment to a variable
completed=$(develop "make the main page blue")

## Get a terminal in the build container with the directory
build-env --source $completed | terminal

## Run the app with the updated source code
build --source $completed | as-service | up --ports 8080:80

## Save the changes to your filesystem
$completed | export .

## Exit
exit
```

## Deploy the agent to GitHub

The next step is to take this agent and deploy it so that it can run automatically. Configure GitHub so that when you label a GitHub issue with "develop", the agent will automatically pick up the task and open a pull request with its solution.

### Create the develop-issue function

The `develop-issue` function will use the github-issue Dagger module from the Daggerverse.

Install the dependency:

```bash
dagger install github.com/kpenfound/dag/github-issue@b316e472d3de5bb0e54fe3991be68dc85e33ef38
```

### Create a GitHub Actions workflow

1. Configure GitHub Actions with the same environment variables that you previously configured locally, as repository secrets.

2. The repository needs to be configured to give GitHub Actions the ability to create pull requests.

3. Create the file `.github/workflows/develop.yml`:

```yaml
name: develop

on:
  issues:
    types:
      - labeled

jobs:
  develop:
    if: github.event.label.name == 'develop'
    name: develop
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: dagger/dagger-for-github@v8.2.0
      - name: Develop
        run: |
          dagger call develop-issue \
          --github-token env://GH_TOKEN \
          --issue-id ${{ github.event.issue.number }} \
          --repository https://github.com/${{ github.repository }}
        env:
          DAGGER_CLOUD_TOKEN: ${{ secrets.DAGGER_CLOUD_TOKEN }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

4. Commit and push your changes to GitHub:

```bash
git add .
git commit -m'deploy agent to github'
git push
```

### Run the agent in GitHub Actions

1. Create a new GitHub issue in your repository.
2. Add the label called "develop".
3. When the label is added, it triggers the GitHub Actions workflow.
4. Once the workflow completes, there will be a new pull request ready to review!

## Next steps

Congratulations! You created an agentic function with a Daggerized project and successfully ran it, both locally and automatically in GitHub.

## See Also

- [installed the Dagger CLI](./ops-getting-started-installation.md)
