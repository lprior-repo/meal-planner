---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-2
heading_path: ["Git sync", "Git sync - Sync mode"]
chunk_type: code
tokens: 913
summary: "Git sync - Sync mode"
---

## Git sync - Sync mode

All scripts, flows and apps located in the workspace will be pushed to the Git repository. You can filter Git sync on [path](./meta-16_roles_and_permissions-index.md#path) so that only the scripts, flows and apps with a matching path will be pushed to the Git repository. By default, everything in [folders](./meta-8_groups_and_folders-index.md) will be synced (with rule `f/**`).

On each [deployment](./meta-0_draft_and_deploy-index.md#deployed-version), only the updated script/flow/app will be pushed to the remote Git repository.

This feature is [Cloud & Enterprise Self-Hosted](/pricing) only.

Note that you can explicitly exclude (or include) specific files or folders to be taken into account with a [`wmill.yaml` file](https://github.com/windmill-labs/windmill-sync-example/blob/main/wmill.yaml).

### Setup

#### 1. Initialize Git repository

First, create a Git repository to store your Windmill workspace:

**Option A: Create empty repository (Recommended)**

Create an empty Git repository on your Git provider (GitHub, GitLab, etc.) without any initial files. Windmill will populate it automatically in the next step.

**Option B: Manual CLI setup**

For more control, you can set up the repository manually using the [Windmill CLI](./meta-3_cli-index.md):

1. Use [Windmill CLI](./meta-3_cli-index.md) to pull the workspace locally:

```bash
wmill sync pull
```

Configure your [`wmill.yaml`](./ops-3_cli-sync.md#wmillyaml) file with the desired filter settings before pushing to Git.

![Pull workpsace](./pull_workspace.png 'Pull workspace')

2. Create a Git repository (in the example, on GitHub) and push the initial workspace content:

```bash
git init
git remote add origin https://github.com/username/reponame.git
git add .
git commit -m 'Initial commit'
git push -u origin main
```

You now have your Windmill workspace on a GitHub repository.

#### 2. Setup in Windmill

1. Go to workspace settings → Git Sync tab
2. Click **+ Add connection**
3. Create or select a [git_repository](../../integrations/git_repository.mdx) resource pointing to your Git repository. You have two authentication options:
   - **GitHub App**: Use the [GitHub App](../../integrations/git_repository.mdx#github-app) for simplified authentication and enhanced security
   - **Personal Access Token**: Use a [token](https://github.com/settings/tokens) with Read-and-write on "Contents". Your URL should be `https://[USERNAME]:[TOKEN]@github.com/[ORG|USER]/[REPO_NAME].git`
4. Select sync mode ([sync mode or promotion mode](#sync-modes))
5. Complete the configuration of the connection and save

![Git sync Setup](./git_sync_setup.png 'Git sync Setup')

If you chose Option A (empty repository), use the "Initialize Git repository" operation to automatically:

- Create the `wmill.yaml` configuration file with your filter settings
- Push the entire workspace content to the Git repository

If the repository already contains a `wmill.yaml` file, the settings will be automatically imported and applied to your workspace configuration.

**Configuration settings**: Git sync filter settings are pulled from the [`wmill.yaml`](./ops-3_cli-sync.md#wmillyaml) file in your repository. Once the connection is saved, you can update settings by changing `wmill.yaml` and pulling the settings via the corresponding button.

![Git sync Settings](./settings_pull.png 'Git sync Settings Pull')

#### Signing commits with GPG

If your repo requires signed commits, you can set up GPG on your Windmill instance.

1. Generate a GPG key pair:

```
gpg --full-generate-key
```

2. Add the key to your GithHub account:

```
gpg --armor --export <key_id>
```

Go to your GitHub account settings => "SSH and GPG keys" and add the GPG public key.

3. Add the private key to your Windmill instance:

```
gpg --armor --export-keys <key_id>
```

In the Windmill workspace "Git Sync" settings, edit the "GPG key" field with the GPG private key. Use the email address associated with the key and set the passphrase if you added one.

![GPG key](./add_gpg_key.png 'GPG key')

:::caution Key ID and Email

Make sure to double check that the email address associated with the key is the same as the one you use to commit to the repo. Furthermore, double check that the key id is the same as the one you see in the "GPG key" field on your GitHub account.

<br />
All commits will now be signed and commited as the user matching the email address associated with the
key. 
:::

#### Azure DevOps with Service Principal setup

In Microsoft Entra ID, create an application and a secret (also known as Service Principal - an identity used by applications to access Azure resources).
Create an `azure` resource on your Windmill instance with the application's `client_id`, `client_secret` and `tenant_id`.
On Azure DevOps, add the application to the DevOps organization with the appropriate permissions.
In Git sync settings of your Windmill instance, define a new repository with URL:

```
https://AZURE_DEVOPS_TOKEN(<path_to_the_azure_resource>)@dev.azure.com/<organization>/<project>/_git/<repository>
```
