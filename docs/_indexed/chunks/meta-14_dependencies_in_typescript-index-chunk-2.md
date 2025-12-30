---
doc_id: meta/14_dependencies_in_typescript/index
chunk_id: meta/14_dependencies_in_typescript/index#chunk-2
heading_path: ["Dependencies in TypeScript", "Lockfile per script inferred from imports (Standard)"]
chunk_type: code
tokens: 724
summary: "Lockfile per script inferred from imports (Standard)"
---

## Lockfile per script inferred from imports (Standard)

In Windmill, you can run scripts without having to [manage a package.json](#lockfile-per-script-inferred-from-a-packagejson) directly. This is achieved by automatically parsing the imports and resolving the dependencies.

When using Bun as the runtime for TypeScript in Windmill, dependencies are resolved directly from the script imports and their imports when using [sharing common logic](./meta-5_sharing_common_logic-index.md). The TypeScript runtime Bun ensures 100% compatibility with Node.js without requiring any code modifications.

```ts
// unpinned import
import { toWords } from 'number-to-words';

// versioned import
import * as wmill from 'windmill-client@1.147.3';
```

Similarly, for TypeScript scripts using Deno as the runtime, the dependencies and their versions are specified directly in the script, and the resolution is managed by Deno. This method allows for direct use of npm imports and Windmill client imports without requiring any additional configuration for dependency management.

```ts
// unpinned import
import { toWords } from 'npm:number-to-words';

// versioned import
import * as wmill from 'npm:windmill-client@1.335.0';
```

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="TypeScript client"
		description="The TypeScript client for Windmill allows you to interact with the Windmill platform using TypeScript in Bun / Deno runtime."
		href="/docs/advanced/clients/ts_client"
	/>
</div>

### Web IDE

When a script is deployed through the Web IDE, Windmill generates a lockfile to ensure that the same [version of a script](./meta-34_versioning-index.md#script-versioning) is always executed with the same versions of its [dependencies](./meta-6_imports-index.md). To generate a lockfile, it analyzes the imports, the imports can use a version pin (e.g. `windmill-client@1.147.3`) or if no version is used, it uses the latest version. Windmill's [workers](./meta-9_worker_groups-index.md) cache dependencies to ensure fast performance without the need to pre-package dependencies - most jobs take under 100ms end-to-end.

At runtime, a deployed script always uses the same version of its dependencies.

At each [deployment](./meta-0_draft_and_deploy-index.md), the lockfile is automatically recomputed from the imports in the script and the imports used by the [relative imports](#sharing-common-logic-with-relative-imports-when-not-using-bundles). The computation of that lockfile is done by a dependency jobs that you can find in the [Runs](./meta-5_monitor_past_and_future_runs-index.md) page.

### CLI

On [local development](./meta-4_local_development-index.md), each script gets:

- a content file (`script_path.py`, `script_path.ts`, `script_path.go`, etc.) that contains the code of the script,
- a metadata file (`script_path.yaml`) that contains the metadata of the script,
- a lockfile (`script_path.lock`) that contains the dependencies of the script.

You can get those 3 files for each script by pulling your workspace with command [`wmill sync pull`](./ops-3_cli-sync.md).

Editing a script is as simple as editing its content. The code can be edited freely in your IDE, and there are possibilities to even run it locally if you have the correct development environment setup for the script language.

Using [wmill CLI](./meta-3_cli-index.md) command [`wmill script generate-metadata`](./concept-3_cli-script.md#re-generating-a-script-metadata-file), lockfiles can be generated and updated as files. The CLI asks the Windmill servers to run dependency job, using either the [package.json (if present)](#lockfile-per-script-inferred-from-a-packagejson) or asking Windmill to automatically resolve it from the script's code as input, and from the output of those jobs, create the lockfiles.
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
