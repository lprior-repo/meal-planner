---
doc_id: meta/1_typescript_quickstart/index
chunk_id: meta/1_typescript_quickstart/index#chunk-3
heading_path: ["TypeScript quickstart", "Code"]
chunk_type: code
tokens: 743
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Demo TS](./demo_ts.png 'Demo TS')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Code editor"
		description="The code editor is Windmill's integrated development environment."
		href="/docs/code_editor"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

There are two options for runtimes in TypeScript:

- Bun (with a [Nodejs](#nodejs) mode if needed)
- [Deno](#deno)

As we picked `TypeScript (Bun)` for this example, Windmill provided some TypeScript boilerplate. Let's take a look:

```typescript
// there are multiple modes to add as header: //nobundling //native //npm //nodejs
// https://www.windmill.dev/docs/getting_started/scripts_quickstart/typescript#modes

// import { toWords } from "number-to-words@1"
import * as wmill from "windmill-client"

// fill the type, or use the +Resource type to get a type-safe reference to a resource
// type Postgresql = object


export async function main(
  a: number,
  b: "my" | "enum",
  //c: Postgresql,
  //d: wmill.S3Object, // https://www.windmill.dev/docs/core_concepts/persistent_storage/large_data_files 
  //d: DynSelect_foo, // https://www.windmill.dev/docs/core_concepts/json_schema_and_parsing#dynamic-select
  e = "inferred type string from default arg",
  f = { nested: "object" },
  g: {
    label: "Variant 1",
    foo: string
  } | {
    label: "Variant 2",
    bar: number
  }
) {
  // let x = await wmill.getVariable('u/user/foo')
  return { foo: a };
}
```

In Windmill, scripts need to have a `main` function that will be the script's
entrypoint. There are a few important things to note about the `main`.

- The main arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Type annotations are used to generate the UI form, and help pre-validate
  inputs. While not mandatory, they are highly recommended. You can customize
  the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

Also take a look at the import statement lines that are commented out.
In TypeScript, [dependencies](./meta-14_dependencies_in_typescript-index.md) and their versions are contained in the script and hence there is no need for any additional steps.
The TypeScript runtime is Bun, which is 100% compatible with Node.js without any code modifications.
You can use npm imports directly in Windmill. The last import line imports the Windmill
client, that is needed for example, to access
[variables](./meta-2_variables_and_secrets-index.md) or
[resources](./meta-3_resources_and_types-index.md). We won't go
into that here.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a package.json directly."
		href="/docs/advanced/imports"
	/>
	<DocCard
		title="TypeScript client"
		description="The TypeScript client for Windmill allows you to interact with the Windmill platform using TypeScript in Bun / Deno runtime."
		href="/docs/advanced/clients/ts_client"
	/>
</div>

Back to our "Hello World". We can clear up unused import statements, change the
main to take in the user's name. Let's also return the `name`, maybe we can use
this later if we use this Script within a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) and need to pass its result on.

```typescript
export async function main(name: string) {
	console.log("Hello world! Oh, it's you %s? Greetings!", name);
	return { name };
}
```
