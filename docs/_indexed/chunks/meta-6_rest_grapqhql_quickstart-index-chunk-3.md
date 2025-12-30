---
doc_id: meta/6_rest_grapqhql_quickstart/index
chunk_id: meta/6_rest_grapqhql_quickstart/index#chunk-3
heading_path: ["Rest / GraphQL quickstart", "Code"]
chunk_type: code
tokens: 1146
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values.

![Editor for GraphQL](./editor_graphql.png 'Code editor GrapQL')

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

### Rest

As we picked `Rest` for this example, Windmill provided some boilerplate. Let's take a look:

```ts
//native
//you can add proxy support using //proxy http(s)://host:port

// native scripts are bun scripts that are executed on native workers and can be parallelized
// only fetch is allowed, but imports will work as long as they also use only fetch and the standard lib

//import * as wmill from "windmill-client"

export async function main(example_input: number = 3) {
  // "3" is the default value of example_input, it can be overriden with code or using the UI
  const res = await fetch(`https://jsonplaceholder.typicode.com/todos/${example_input}`, {
    headers: { "Content-Type": "application/json" },
  });
  return res.json();
}

```

Rest scripts are in fact [Bun TypeScript](./meta-1_typescript_quickstart-index.md) fetches.
They support all the normal signatures of normal TypeScript but only [stdlib](https://en.wikibooks.org/wiki/C_Programming/stdlib.h) JavaScript, and the fetch operations (including fetch operations from npm packages and relative imports).
For example, the full [wmill API](./ops-2_clients-ts-client.md) is supported, just use:

```ts
import * as wmill from './windmill.ts'
```

The `// native` header line will help Windmill automatically convert between 'nativets' and 'bun' scripts based on the presence of this header so you can always just pick TypeScript (Bun) and decide at the end if you want to accelerate it with 'native' if possible.
The REST button simply prefills a Bun script with a `//native` header. 

Fetches can also be done through a regular TypeScript in Windmill (without the `//native` header), but opting for dedicated Rest scripts
benefits from a highly efficient runtime.

Replace the `<jsonplaceholder>` URL with the API endpoint of your choice and customize the headers object according to your fetch requirements.

REST scripts benefit from the [auto-generated UI](./meta-6_auto_generated_uis-index.md) capabilities of any Windmill script.
The arguments of the `main` function are used for generating 1. the input spec of the Script,
and 2. the frontend that you see when running the Script as a standalone app.
Type annotations are used to generate the UI form, and help pre-validate
inputs. While not mandatory, they are highly recommended. You can customize the UI in later steps (but not change the input type!).

This is also a way to have users fill [resources](./meta-3_resources_and_types-index.md) or [variables](./meta-2_variables_and_secrets-index.md) through the auto-generated UI. The UI is available in the script editor to [test your code](./meta-23_instant_preview-index.md):

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/rest_supabase.mp4"
/>

<br />

> In the example above, a custom resource is declared as a parameter of the main function. It will be asked by the user through the auto-generated UI and used directly in the script (here for the bearer token).

If the endpoint is and HTTPS endpoint exposing custom certificate, the fetch will fail. Custom certificates can be trusted using the `DENO_CERT` env variable (see [Deno official documentation](https://docs.deno.com/runtime/manual/getting_started/setup_your_environment#environment-variables))

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="On top of its integrated editors, Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

### GraphQL

As we picked `GraphQL` for this example, Windmill provided some boilerplate. Let's take a look:

```ts
query($name1: String, $name2: Int, $name3: [String]) {
	demo(example_name_1: $name1, example_name_2: $name2, example_name_3: $name3) {
		example_name_1,
		example_name_2,
		example_name_3
	}
}
```

The query itself is similar to any GraphQL query.

To trigger each GraphQL script, an input named 'api' will be required. This is a [GraphQL resource](https://hub.windmill.dev/resource_types/112/graphql) defined by the JSON schema:

```js
{
    "type": "object",
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "required": [
        "base_url"
    ],
    "properties": {
        "base_url": {
            "type": "string",
            "format": "uri",
            "default": "",
            "description": ""
        },
        "bearer_token": {
            "type": "string",
            "default": "",
            "description": ""
        },
        "custom_headers": {
            "type": "object",
            "description": "",
            "properties": {},
            "required": []
        }
    }
}
```

[Resources](./meta-3_resources_and_types-index.md) are rich objects in JSON that allow to store configuration and credentials. They can be saved, named, and shared within Windmill to control and streamline the execution of GraphQL scripts.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Resources and resource types"
		description="Resources are structured configurations and connections to third-party systems, with Resource types defining the schema for each Resource."
		href="/docs/core_concepts/resources_and_types"
	/>
</div>

The arguments of the query will be used for generating 1. the input spec of the Script,
and 2. the frontend that you see when running the Script with an [auto-generated UI](./meta-6_auto_generated_uis-index.md).
Type annotations are used to generate the UI form, and help pre-validate
inputs. While not mandatory, they are highly recommended. You can customize the UI in later steps (but not change the input type).

The UI is available in the script editor to [test your code](./meta-23_instant_preview-index.md):

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/graphql_example.mp4"
/>

<br />

> In the example above, a [GraphQL resource](https://hub.windmill.dev/resource_types/112/graphql) is used with details on base URL and bearer token. Also was used the [auto-generated UI](./meta-6_auto_generated_uis-index.md) to fill the argument `login`.
