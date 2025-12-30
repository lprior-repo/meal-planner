---
doc_id: meta/14_dependencies_in_typescript/index
chunk_id: meta/14_dependencies_in_typescript/index#chunk-5
heading_path: ["Dependencies in TypeScript", "Other"]
chunk_type: code
tokens: 703
summary: "Other"
---

## Other

Two tricks can be used: [Relative Imports](#sharing-common-logic-with-relative-imports-when-not-using-bundles) and [Private npm registry & private npm packages](#private-npm-registry--private-npm-packages). Both are compatible with the methods described above.

### Sharing common logic with relative imports when not using bundles

If you want to share common logic with Relative Imports when not using [Bundles](#bundle-per-script-built-by-cli), this can be done easily using [relative imports](./meta-5_sharing_common_logic-index.md) in both Bun and Deno.

This applies for all methods above, except absolute imports do not work for [codebases and bundles](#bundle-per-script-built-by-cli).

Note that in both the webeditor and with the CLI, your scripts do not necessarily need to have a main function. If they don't, they are assumed to be shared logic and not runnable scripts.

It works extremely well in combination with [Developing scripts locally](./meta-4_local_development-index.md) and you can easily sync your scripts with the [CLI](./meta-3_cli-index.md).

It is possible to import directly from other TypeScript scripts. One can simply follow the path layout. For instance,
`import { foo } from "./script_name.ts"`. A more verbose example below:

```typescript
import { main as foo, util } from './my_script_path.ts';
```

Relative imports syntax is much preferred as it will work on [local editors](./meta-4_local_development-index.md) without further configuration.

In TypeScript Bun, you can drop the .ts extension so:

```typescript
import { main as foo, util } from './my_script_path';
```

would work too.

You may also use absolute imports:

```typescript
import { main as foo, util } from '/f/<foldername>/script_name.ts';

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

Note that path in Windmill can have as many depth as needed, so you can have paths like this `f/folder/subfolder/my_script_path.ts` and relative imports will work at any level. Hence, it will work exactly the same as on local.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Sharing common logic"
		description="It is common to want to share common logic between your scripts. This can be done easily using relative imports in both Python and TypeScript."
		href="/docs/advanced/sharing_common_logic"
	/>
</div>

### Private npm registry & private npm packages

You can use private npm registries and private npm packages in your TypeScript scripts.

This applies to all methods above. Only, if using Codebases & bundles locally, there is nothing to configure in Windmill, because the bundle is built locally using your locally-installed modules (which support traditional npm packages and private npm packages).

![Private NPM registry](../6_imports/private_registry.png 'Private NPM registry')

On [Enterprise Edition](/pricing), go to [Instance settings](./meta-18_instance_settings-index.md#registries) -> Registries.

Set the registry URL: `https://npm.pkg.github.com/OWNER` (replace `OWNER` with your GitHub username or organization name).

Currently, Deno does not support private npm packages requiring tokens (but support private npm registries). Bun however does.

If a token is required, append `:_authToken=<your token>` to the URL (replace `<your token>` with your actual token).

Combining the two, you can import private packages from npm

```yaml
https://registry.npmjs.org/:_authToken=***REMOVED***
```

If the private registry is exposing custom certificates,`DENO_CERT` and `DENO_TLS_CA_STORE` env variables can be used as well (see [Deno documentaion](https://docs.deno.com/runtime/manual/getting_started/setup_your_environment#environment-variables) for more info on those options).

```dockerfile
windmill_worker:
  ...
  environment:
    ...
    - DENO_CERT=/custom-certs/root-ca.crt
```

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Private npm registry & private npm packages"
		description="Import private packages from npm in Windmill."
		href="/docs/advanced/dependencies_in_typescript#private-npm-registry--private-npm-packages"
	/>
</div>
