---
doc_id: meta/4_local_development/index
chunk_id: meta/4_local_development/index#chunk-2
heading_path: ["Local development", "Local development recommended setup"]
chunk_type: prose
tokens: 481
summary: "Local development recommended setup"
---

## Local development recommended setup

Local development involves two components:

1. Being able to create and edit Windmill scripts and flow from your favorite IDE.
2. Deploy them to Windmill and at the same time [version](./meta-13_version_control-index.md) them in a Git repository.

In addition to the core functionalities just mentioned, some might want to add the concept of [deployment](./meta-12_deploy_to_prod-index.md). This encompasses having a staging and production Windmill environment, and being able to deploy from Staging to Production.

The diagram below illustrates the full process. We're going to explain it quickly, and in the following sections we will decompose it.

![Local development](./local_development.png)

It works as follows:

- 2 different workspaces exist in Windmill: one for Staging and one for Prod, and a Git repository that has been set to sync the Windmill Staging workspace.
- Some developers work from their favorite IDE. They can create new Windmill scripts and flows, edit existing ones, and push them to the Staging repository. Some developers can work directly in Windmill's web IDE. All of this happens in the Staging workspace.
- Every time a script or a flow is deployed in the Staging workspace, Windmill will automatically commit the change to the Git repository using [Git sync](./meta-11_git_sync-index.md). It can either commit directly to a specific (i.e. `staging`) branch, or open PRs to this branch (one PR per script/flow).
- Within the Git repository, every time the `staging` branch is merged into the production branch (i.e. `main`), all the changes are pushed at once the Windmill Production workspace.

To summarize, developers operate only in Windmill Staging workspace. Windmill Production workspace is updated only by the CI when the Git staging branch is merged into the production branch.

Now let's deep dive into the first part. We will first explain how developers can set up their local environment to be able to create and edit Windmill script from their IDE, then we will see how to sync Windmill workspaces to a Git repository.

The second part is well covered in:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Deploy to prod using a git workflow"
		description="Windmill integration with Git repositories makes it possible to adopt a robust development process for your Windmill scripts, flows and apps."
		href="/docs/advanced/deploy_gh_gl"
	/>
</div>
