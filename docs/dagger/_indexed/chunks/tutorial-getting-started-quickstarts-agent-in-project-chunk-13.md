---
doc_id: tutorial/getting-started/quickstarts-agent-in-project
chunk_id: tutorial/getting-started/quickstarts-agent-in-project#chunk-13
heading_path: ["quickstarts-agent-in-project", "Deploy the agent to GitHub"]
chunk_type: code
tokens: 328
summary: "The next step is to take this agent and deploy it so that it can run automatically."
---
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
