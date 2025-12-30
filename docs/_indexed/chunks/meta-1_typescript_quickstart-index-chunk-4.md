---
doc_id: meta/1_typescript_quickstart/index
chunk_id: meta/1_typescript_quickstart/index#chunk-4
heading_path: ["TypeScript quickstart", "Modes"]
chunk_type: code
tokens: 826
summary: "Modes"
---

## Modes

### Pre-bundling and nobundling

Windmill [pre-bundles](/changelog/pre-bundle-bun-scripts) your script at deployment time using [Bun bundler](https://bun.sh/docs/bundler). This improve memory usage and speed up the execution time of your script. If you would like to disable this feature, you can add the following comment at the top of your script:

```ts
//nobundling
```

### Native

Windmill provides a runtime that is more lightweight but supports less features and allow to run scripts in a more lightweight manner with direct bindings to v8. To enable, you can add the following comment at the top of your script:

```ts
//native
```

To learn more, see [Rest](./meta-6_rest_grapqhql_quickstart-index.md) scripts, that are under the hood Bun TypeScripts with a `//native` header.

### NodeJS

Windmill provides a true NodeJS compatibility mode. This means that you can run your existing NodeJS code without any modifications.

The only thing you need to do is to select `TypeScript (Bun)` as the runtime and as the first line, use:

```ts
//nodejs
```

![Nodejs Compatibility](./nodejs_compatibility.png 'Nodejs Compatibility')

This method is an escape hatch for using another runtime (NodeJS), but it is slower than Deno and Bun since it resorts to Bun under the hood.

This feature is exclusive to [Cloud plans and Self-Hosted Enterprise edition](/pricing).

### Npm

Similarly, you can use `npm install` instead of `bun install` to install dependencies. This is useful as an escape hatch for cases not supported by bun:

```ts
//npm
```

This is also exclusive to [Cloud plans and Self-Hosted Enterprise edition](/pricing).

### Deno

As we picked `TypeScript (Deno)` for this example, Windmill provided some TypeScript boilerplate. Let's take a look:

```typescript
// Ctrl/CMD+. to cache dependencies on imports hover.

// Deno uses "npm:" prefix to import from npm (https://deno.land/manual@v1.36.3/node/npm_specifiers)
// import * as wmill from "npm:windmill-client@1.525.0"

// fill the type, or use the +Resource type to get a type-safe reference to a resource
// type Postgresql = object

export async function main(
  a: number,
  b: "my" | "enum",
  //c: Postgresql,
  d = "inferred type string from default arg",
  e = { nested: "object" },
  //e: wmill.Base64
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
The resolution is done by [Deno](https://deno.com/runtime).
You can use npm imports directly in Windmill. The last import line imports the Windmill
client, that is needed for example, to access
[variables](./meta-2_variables_and_secrets-index.md) or
[resources](./meta-3_resources_and_types-index.md). We won't go
into that here.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
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
