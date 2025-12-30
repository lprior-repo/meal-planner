---
doc_id: meta/5_sharing_common_logic/index
chunk_id: meta/5_sharing_common_logic/index#chunk-7
heading_path: ["Sharing common logic", "Deno or Bun relative imports for sharing common logic"]
chunk_type: code
tokens: 412
summary: "Deno or Bun relative imports for sharing common logic"
---

## Deno or Bun relative imports for sharing common logic

Similarly to [Python](#python-relative-imports-for-sharing-common-logic), it is possible to import directly from other TypeScript scripts. One can simply follow the path layout. For instance,
`import { foo } from "/f/<foldername>/script_name.ts"`. A more verbose example below:

```typescript
import { main as foo, util } from '../my_script_path.ts';
```

With [Bun](./meta-1_typescript_quickstart-index.md), you don't need to specify the `.ts` file extension (it is only required for the [Deno](./meta-1_typescript_quickstart-index.md#deno) runtime):

```typescript
import { main as foo, util } from '../my_script_path';
```

Relative imports syntax is much preferred as it will work on [local editors](./meta-4_local_development-index.md) without further configuration.

You may also use absolute imports:

```typescript
import { main as foo, util } from '/f/common/my_script_path';

export async function main() {
	await foo();
	util();
}
```

but to make it work with your local editor, you will need the following configuration in tsconfig.json

```json
{
	"compilerOptions": {
		"paths": {
			"/*": ["./*"]
		}
	}
}
```

Note that [paths](./meta-16_roles_and_permissions-index.md#path) in Windmill can have as many depth as needed, so you can have paths like this `f/folder/subfolder/my_script_path` and relative imports will work at any level. Hence, it will work exactly the same as on local.

### Bundle per script built by CLI

This method can only be deployed from the [CLI](./meta-3_cli-index.md), on [local development](./meta-4_local_development-index.md).

To work with large custom codebases, there is another mode of deployment that relies on the same mechanism as similar services like Lambda or cloud functions: a bundle is built locally by the CLI using [esbuild](https://esbuild.github.io/) and deployed to Windmill.

This bundle contains all the code and dependencies needed to run the script.

Windmill CLI, it is done automatically on `wmill sync push` for any script that falls in the patterns of includes and excludes as defined by the [wmill.yaml](./meta-33_codebases_and_bundles-index.md#wmillyaml) (in the codebase field).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Codebases & bundles"
		description="Deploy scripts with any local relative imports as bundles."
		href="/docs/core_concepts/codebases_and_bundles"
	/>
</div>
