---
doc_id: meta/4_local_development/index
chunk_id: meta/4_local_development/index#chunk-3
heading_path: ["Local development", "Develop locally"]
chunk_type: code
tokens: 492
summary: "Develop locally"
---

## Develop locally

You can develop locally by using [Windmill CLI](./meta-3_cli-index.md) to clone a workspace and edit scripts and flows in your favorite IDE.

Here is a quickstart video:

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="Local development quickstart"
	src="/videos/local_dev_quickstart.mp4"
/>

<br />

All details and commands are available [below](#editing-and-creating-scripts-locally).

### Setting up the workspace folder

Developing Windmill scripts and flows from your favorite IDE is made easy by using Windmill CLI. Here we will go through the full process of cloning a Windmill workspace locally, creating and editing new scripts and flows, and pushing them back the Windmill workspace.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Command-line interface (CLI)"
		description="The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
</div>

The first step is to clone an existing Windmill workspace into a local folder.

Create an empty folder:

```bash
mkdir myworkspace
cd myworkspace
```

Add the workspace and pull its the content using the [CLI `pull` command](./ops-3_cli-sync.md#raw-syncing):

```bash
wmill workspace add myworkspace [workspace_id] [remote]
wmill sync pull
```

This will download the content of the workspace into your local folder. You will see an `f/` and a `u/` folder appearing, replicating the folder structure of the workspace.

:::caution

[`wmill sync pull`](./ops-3_cli-sync.md) will pull everything from the Windmill workspace, including resources and variables, even secrets. If you're planning to use Git as explained below, we recommend only pulling scripts, flows and apps, skipping the rest. It can be done with:

```bash
wmill sync pull --skip-variables --skip-secrets --skip-resources
```

:::

Each script will be represented by a content file (`.py`, `.ts`, `.go` depending on the language) plus a metadata file (ending with `.script.yaml`). This file contains various metadata about the script, like a summary and description, but also the content of the lockfile and the schema of the script (i.e. the signature of its `main` method). We will come back to this later.
For flows, one flow will be represented by a folder, containing a `flow.yaml` file being the definition of the flow, and additional files for inline scripts.

:::tip

The metadata file schema is available [here](./meta-13_json_schema_and_parsing-index.md).

:::

### Editing and creating scripts locally

To summarize, here are the canonical process to edit and create scripts locally using [Windmill CLI](./meta-3_cli-index.md) (details below):

```bash
