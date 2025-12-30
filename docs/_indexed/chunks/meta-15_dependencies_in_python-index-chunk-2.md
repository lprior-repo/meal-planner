---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-2
heading_path: ["Dependencies in Python", "Lockfile per script inferred from imports (Standard)"]
chunk_type: prose
tokens: 737
summary: "Lockfile per script inferred from imports (Standard)"
---

## Lockfile per script inferred from imports (Standard)

In Windmill, you can run scripts without having to [manage a requirements.txt](#lockfile-per-script-inferred-from-a-requirementstxt) directly. This is achieved by automatically parsing the top-level imports and resolving the dependencies. For automatic dependency installation, Windmill will only consider these top-level imports.

In Python, the top-level imports are automatically parsed on saving of the script and a list of imports is generated. For automatic dependency installation, Windmill will only consider these top-level imports.

A dependency job is then spawned to associate that list of PyPI packages with a lockfile, which will lock
the versions. This ensures that the same version of a Python script is always
executed with the same versions of its dependencies. It also avoids the hassle
of having to maintain a separate requirements file.

We use a simple heuristics to infer the package name: the import root name must be the package name. We also maintain a list of exceptions.
You can make a PR to add your dependency to the list of exceptions [here](https://github.com/windmill-labs/windmill/blob/main/backend/parsers/windmill-parser-py-imports/src/mapping.rs).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Python client"
		description="The Python client library for Windmill provides a convenient way to interact with the Windmill platform's API from within your script jobs."
		href="/docs/advanced/clients/python_client"
	/>
</div>

### Web IDE

When a script is deployed through the Web IDE, Windmill generates a lockfile to ensure that the same [version of a script](./meta-34_versioning-index.md#script-versioning) is always executed with the same versions of its [dependencies](./meta-6_imports-index.md). To generate a lockfile, it analyzes the imports, the imports can [use a version pin](#pinning-dependencies-and-requirements) or if no version is used, it uses the latest version. Windmill's [workers](./meta-9_worker_groups-index.md) cache dependencies to ensure fast performance without the need to pre-package dependencies - most jobs take under 100ms end-to-end.

At runtime, a deployed script always uses the same version of its dependencies.

At each [deployment](./meta-0_draft_and_deploy-index.md), the lockfile is automatically recomputed from the imports in the script and the imports used by the [relative imports](#sharing-common-logic-with-relative-imports). The computation of that lockfile is done by a dependency jobs that you can find in the [Runs](./meta-5_monitor_past_and_future_runs-index.md) page.

### CLI

On [local development](./meta-4_local_development-index.md), each script gets:
- a content file (`script_path.py`, `script_path.ts`, `script_path.go`, etc.) that contains the code of the script,
- a metadata file (`script_path.yaml`) that contains the metadata of the script,
- a lockfile (`script_path.lock`) that contains the dependencies of the script.

You can get those 3 files for each script by pulling your workspace with command [`wmill sync pull`](./ops-3_cli-sync.md).

Editing a script is as simple as editing its content. The code can be edited freely in your IDE, and there are possibilities to even run it locally if you have the correct development environment setup for the script language.

Using [wmill CLI](./meta-3_cli-index.md) command [`wmill script generate-metadata`](./concept-3_cli-script.md#re-generating-a-script-metadata-file), lockfiles can be generated and updated as files. The CLI asks the Windmill servers to run dependency job, using either the [requirements.txt (if present)](#lockfile-per-script-inferred-from-a-requirementstxt) or asking Windmill to automatically resolve it from the script's code as input, and from the output of those jobs, create the lockfiles.
When a lockfile is present alongside a script at time of deployment by the CLI, no dependency job is run and the present lockfile is used instead.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Command-line interface (CLI)"
		description="The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
	<DocCard
		title="Local development"
		description="Develop locally, push to git and deploy automatically to Windmill."
		href="/docs/advanced/local_development"
	/>
</div>
