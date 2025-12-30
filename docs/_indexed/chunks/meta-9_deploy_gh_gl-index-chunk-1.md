---
doc_id: meta/9_deploy_gh_gl/index
chunk_id: meta/9_deploy_gh_gl/index#chunk-1
heading_path: ["Deploy to prod using a git workflow"]
chunk_type: prose
tokens: 895
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Deploy to prod using a git workflow

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Windmill integration with Git repositories makes it possible to adopt a robust development process for your Windmill scripts, flows and apps.

This is the recommended way to deploy to prod in Windmill.

:::info Deploy to prod in Windmill

For all details on Deployments to prod in Windmill, see [Deploy to prod](./meta-12_deploy_to_prod-index.md).

:::

![Local development Setup](../4_local_development/local_development.png 'Local development Setup')

> See section [Setup the full Git workflow](#setup-the-full-git-workflow) for the detailed setup steps.

<br />

The integration with git works in three-folds:

1. [GitHub Action](https://docs.github.com/en/actions) + [CLI](./meta-3_cli-index.md): upon any commit to a particular branch, the GitHub action will run the `wmill` CLI and push to a Windmill workspace this works using the CLI doing `wmill sync push` ([free & open source](/pricing)).

:::tip

You can also trigger a webhook and push the changes to Windmill using [this Windmill script](https://hub.windmill.dev/scripts/windmill/11414/git-sync-push-windmill) and pass the arguments as query args in the webhook triggered after pushing to the repo.

:::

2. [Git sync](./meta-11_git_sync-index.md) (Sync mode): Windmill automatically committing to a git repository upon any deployment to a workspace, this works using the CLI doing `wmill sync pull` ([Cloud and Enterprise Self-Hosted](/pricing)). Having it commit back to Windmill has 2 benefits:

   - It ensures that any automatically created metadata files are wrote-back (in case you pushed a script without its metadata for instance).
   - It ensures that any modification done in the UI is kept in sync with the git repository and guarantees a bi-sync between the repo and the UI.

3. [Git sync](./meta-11_git_sync-index.md) (Promotion mode): Windmill automatically creates a branch specific to that item (and whose name is derived from that item) that targets the branch set in the git sync settings, upon any change to any items, be it from the UI or from git ([Cloud and Enterprise Self-Hosted](/pricing)). This should be coupled with a GitHub action that automatically create a PR when a branch is created. This PR can then be reviewed and merged. Upon being merged to the prod branch, a GitHub action as described in 1. would then deploy it to the prod branch.

Once everything is set up, the process is as follows:

- Users iterate and make their changes in the "staging" Windmill workspace UI or in the git staging branch directly.
- Every time a Windmill App, Flow or Script is deployed to that workspace (via Windmill's UI or through the GitHub action that deploys to staging upon any change), Windmill automatically sync it back to the repo on the "staging" branch (Git sync - sync mode) and also create a branch that targets prod and keep it in sync with any new changes (Git sync - Promotion mode)
- On every new branch created, PRs are automatically created via a GitHub Action. Approved GitHub users can review and merge those PRs.
- Every time a PR is merged, another GitHub Action automatically deploys the change to a "production" Windmill workspace.

Note that although the CLI is used by both the GitHub Action and the Git sync, the CLI does not need to be used directly by any users and everything happen behind the scene in an automated way.

This gives the flexibility to fully test new Windmill scripts, flows and apps, while having them [version-controlled](./meta-13_version_control-index.md) and deployed in an automated way to the production environment.

This process can be used in particular for [local development](./meta-4_local_development-index.md).

:::tip

Check out the [windmill-sync-example repository](https://github.com/windmill-labs/windmill-sync-example) as an illustration of this process.

:::

Deploying to a prod workspace using git requires the [Git sync](./meta-11_git_sync-index.md) feature, which is is a [Cloud plans and Self-Hosted Enterprise Edition](/pricing)-only feature.

From the workspace settings, you can set a [git_repository](../../integrations/git_repository.mdx) resource on which the workspace will automatically commit and push scripts, flows and apps to the repository on each [deploy](./meta-0_draft_and_deploy-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Git sync"
		description="Connect a Windmill workspace to a Git repository to automatically commit and push scripts, flows and apps to the repository on each deploy."
		href="/docs/advanced/git_sync"
	/>
</div>
