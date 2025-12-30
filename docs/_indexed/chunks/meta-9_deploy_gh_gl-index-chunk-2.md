---
doc_id: meta/9_deploy_gh_gl/index
chunk_id: meta/9_deploy_gh_gl/index#chunk-2
heading_path: ["Deploy to prod using a git workflow", "Setup the full Git workflow"]
chunk_type: code
tokens: 1981
summary: "Setup the full Git workflow"
---

## Setup the full Git workflow

Note: this is the detailed setup steps for a [GitHub](https://github.com/) repository. It will need to be adapted for [GitLab](https://about.gitlab.com/).

The video below shows a simplified setup, see the steps below it for the full setup.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/es8FUC2M73o"
	title="Deploy to a Prod Workspace using a Git Workflow"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

:::warning
If you are not using the [Enterprise Edition](/pricing) (EE) version of Windmill, you can still follow the parts of this guide that do not involve Git sync.
:::

:::tip
The guide covers a staging and prod setup. To add an additional dev environment, simply consider staging to be the target of the dev workspace and prod to be the target of the staging workspace.
:::

### Pull workspace locally

1. Open your terminal and add your workspace to the [Windmill CLI](./meta-3_cli-index.md) using the command:
   ```bash
   wmill workspace add <workspace-name> <workspace-id> <url>
   ```
2. Authorize the CLI to access the workspace.
3. [Pull](./ops-3_cli-sync.md) the entire Windmill workspace locally to your machine.

The CLI is able to sync [variables](./meta-2_variables_and_secrets-index.md), [resources](./meta-3_resources_and_types-index.md) and [secrets](./meta-2_variables_and_secrets-index.md#secrets) as well. However, everywhere the CLI is used here, it it set with the flags `--skip-variables --skip-secrets --skip-resources` to avoid syncing them. This is because variables, resources and secrets should have values that are specific to each environment.

For instance, a [resource](./meta-3_resources_and_types-index.md) named `f/myproject/myimportantdb` should have a different value in staging and prod. This is why they are not synced and should be set manually in each environment. You can however if you prefer, manually sync those. Do note that secrets have an additional layer of encryption and are by default exported in their encrypted form whose decryption key is workspace specific. To sync them between workspace, use `--plain-secrets` to export them in plain text.

### Push workspace to GitHub

1. Create a new private repository on GitHub.
2. Use the [suggested Git commands](./meta-11_git_sync-index.md#push-workspace-to-github) to push your local repository to GitHub.
3. Verify that your workspace is now available in the GitHub repository.

### Setup git sync

1. In Windmill, navigate to the workspace settings and go to the [Git sync](./meta-11_git_sync-index.md) tab.
2. Create a `git_repository` [resource](./meta-3_resources_and_types-index.md) with the necessary URL, username, repo name, and a GitHub token. You can also use a [GitHub app installation](../integrations/git_repository#github-app) to connect a repo to your windmill instance.
3. Generate a fine-grained GitHub [token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token) with read and write permissions for content and add it to the Windmill `git_repository` resource.

Your URL should be `https://[USERNAME]:[TOKEN]@github.com/[ORG|USER]/[REPO_NAME].git`

If you do the setup with a staging workspace, you can set the branch to 'Staging'.

Test git sync:

1. Create a [folder](./meta-8_groups_and_folders-index.md) in your Windmill workspace and add scripts, apps, and flows to it.
2. Verify that these items are pushed to the GitHub repository and appear in the correct folder structure.

### Deploy to a prod workspace using a git workflow

1. Set up a new empty workspace in Windmill that will be the target of the prod branch.
2. Enable the [Create one branch per deployed object](./meta-11_git_sync-index.md#create-one-branch-per-deployed-object) option in the Git sync settings.
3. In GitHub, [allow actions](https://docs.github.com/en/enterprise-server@3.10/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#preventing-github-actions-from-creating-or-approving-pull-requests) to create and approve pull requests.
4. Create a [user token](./meta-4_webhooks-index.md#user-token) in Windmill and save it as a [secret](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository) named `WMILL_TOKEN` in your GitHub repository Settings > "Secret and Variable" > "Actions".

Test deploy to prod workspace:

1. From the staging workspace, create a new flow and save it in a folder.
2. Verify that a new branch is created in the GitHub repository and a pull request is opened.
3. Merge the pull request and check that the changes are deployed to the prod workspace in Windmill.

### GitHub Actions setup

1. Add [GitHub Actions](https://github.com/features/actions) to your repository. You will find the necessary actions in the [windmill-sync-example repository](https://github.com/windmill-labs/windmill-sync-example).
2. Create a `.github/workflows` directory in your repository and add the following files:
   - `open-pr-on-commit.yaml`: This action automatically creates a PR when Windmill commits a change.
   - `push-on-merge.yaml`: This action automatically pushes the content of the repo to the Windmill prod workspace when a PR is merged. Update the `WMILL_WORKSPACE` variable to the name of your prod workspace.
   - Optionnaly, if you want to add a staging workspace, copy the previous GitHub action/workflow file but now set the `WMILL_WORKSPACE` variable to the id of the staging workspace and the `WMILL_URL` variable to the base URL of the Windmill instance if different than the one for prod. Also changes the trigger to listen to the branches: 'staging'.
   - `push-on-merge-to-forks.yaml`: This does the same as `push-on-merge.yaml` but for all [Workspace Forks](./meta-20_workspace_forks-index.md), enabling the full power of the feature.

On top of `WMILL_TOKEN`, 2 other variables need to be set in the GitHub action workflow file:

- `WMILL_WORKSPACE`: the name of the workspace
- `WMILL_URL`: the base URL of the Windmill instance (e.g. https://app.windmill.dev/)

<Tabs className="unique-tabs">
<TabItem value="open-pr-on-commit.yaml" label="open-pr-on-commit.yaml" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```yaml
name: Windmill Pull Request
on:
  push:
    branches:
      - wm_deploy/github-sync-example-staging/**
      - wm-fork/**

env:
TARGET_BRANCH: main

jobs:
submit_pull_requests:
runs-on: ubuntu-latest
permissions:
contents: read
pull-requests: write

    steps:
      - uses: actions/checkout@v4
      - name: Create pull request
        run: |
          gh pr view ${{ github.ref_name }} \
          && gh pr reopen ${{ github.ref_name }} \
          || gh pr create -B ${{ env.TARGET_BRANCH }} -H ${{ github.ref_name }} \
          --title "${{github.event.head_commit.message }}" \
          --body "PR created by Github action '${{ github.workflow }}'"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

````
</TabItem>
<TabItem value="push-on-merge.yaml" label="push-on-merge.yaml" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```yaml
name: "Push main to Windmill workspace"
on:
  workflow_dispatch:
  push:
    branches:
      - "main"
    # if the windmill workspace is persisted in a subfolder of this repos, you can add the following to avoid pushing to windmill when there's no change
    # paths:
    #   - wm/**

env:
  WMILL_URL: https://app.windmill.dev/
  WMILL_WORKSPACE: github-sync-example-prod

jobs:
  sync:
    environment: windmill
    runs-on: "ubuntu-latest"
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      # We check the commit to make sure it doesn't start with [WM] which commits coming from Windmill Git Sync do.\
      # If that's the case, then we stop the workflow as we want to avoid overwriting changes that are out-of-sync
      # (for instance if one were to deploy in quick succession)
      - name: Check commit message
        id: check_message
        run: |
          COMMIT_MESSAGE="${{ github.event.head_commit.message }}"
          if [[ "$COMMIT_MESSAGE" =~ ^\[WM\] ]]; then
            echo "Commit message starts with '[WM]', skipping push to Windmill to avoid overwriting deploy that immediately follows it"
            echo "skip=skip" >> $GITHUB_OUTPUT
          fi

      # (push will pull first to detect conflicts and only push actual changes)
      - name: Push changes
        if: steps.check_message.outputs.skip != 'skip'
        run: |
          npm install -g windmill-cli@1.393.3
          wmill sync push --yes --skip-variables --skip-secrets --skip-resources --workspace ${{ env.WMILL_WORKSPACE }} --token ${{ secrets.WMILL_TOKEN }} --base-url ${{ env.WMILL_URL }}
````

</TabItem>
<TabItem value="push-on-merge-to-forks.yaml" label="push-on-merge-to-forks.yaml" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```yaml
name: "Push forks to Windmill workspace forks"
on:
  workflow_dispatch:
  push:
    branches:
      - wm-fork/**
    # if the windmill workspace is persisted in a subfolder of this repos, you can add the following to avoid pushing to windmill when there's no change
    # paths:
    #   - wm/**

env:
WMILL_URL: https://app.windmill.dev/

jobs:
sync:
environment: windmill
runs-on: "ubuntu-latest"
steps: - name: Checkout
uses: actions/checkout@v3

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Extract workspace from branch name
        id: workspace
        run: |
          BRANCH_NAME=${GITHUB_REF#refs/heads/}
          WORKSPACE=$(echo "$BRANCH_NAME" | sed 's|wm-fork/|wm-fork-|' | sed 's|/|-|g')
          echo "workspace=$WORKSPACE" >> $GITHUB_OUTPUT

      # We check the commit to make sure it doesn't start with [WM] which commits coming from Windmill Git Sync do.\
      # If that's the case, then we stop the workflow as we want to avoid overwriting changes that are out-of-sync
      # (for instance if one were to deploy in quick succession)
      - name: Check commit message
        id: check_message
        run: |
          COMMIT_MESSAGE="${{ github.event.head_commit.message }}"
          if [[ "$COMMIT_MESSAGE" =~ ^\[WM\] ]]; then
            echo "Commit message starts with '[WM]', skipping push to Windmill to avoid overwriting deploy that immediately follows it"
            echo "skip=skip" >> $GITHUB_OUTPUT
          fi

      # (push will pull first to detect conflicts and only push actual changes)
      - name: Push changes
        if: steps.check_message.outputs.skip != 'skip'
        run: |
          npm install -g windmill-cli@1.393.3
          wmill sync push --yes --skip-variables --skip-secrets --skip-resources --workspace ${{ steps.workspace.outputs.workspace }} --token ${{ secrets.WMILL_TOKEN }} --base-url ${{ env.WMILL_URL }}

````
</TabItem>
</Tabs>

### Testing

You are now ready to test the workflow. You can do so by:
1. Create and deploy a new script in the staging workspace, give it a path within the allowed [filters](./meta-11_git_sync-index.md#path-filters).
2. Verify in the GitHub action run that the sync push has been able to push the change to the staging workspace (or the prod workspace if you have not set up a staging workspace).
3. Check the target workspace in Windmill if the script has been deployed.
4. Go to the runs page, toggle the "Sync" kind of jobs. You should see at least 2 jobs, one to push back your change to the staging (if set) workspace (no-op), and one to create a branch that targets the main branch (the one that will be merged).
5. Now in your repository, you should see a new branch named wm_deploy/[WORKSPACE_NAME]/[SCRIPT_PATH] (for instance wm_deploy/staging/f/example/script).
6. Merge that branch, now the changes should trigger the "Deploy to prod" GitHub action in the main branch.
