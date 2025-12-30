---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-9
heading_path: ["JSON schema and parsing", "Backend schema validation"]
chunk_type: prose
tokens: 349
summary: "Backend schema validation"
---

## Backend schema validation

By default, the schema is not explicitly checked by Windmill. For example, when triggering a script via [webhook](./meta-4_webhooks-index.md), it is possible to pass an arbitrary JSON payload for the arguments, and Windmill [workers](./meta-9_worker_groups-index.md) will just try to execute the script with it.

In some cases, you might want the job to fail if the payload does not follow the defined schema. For this, just add the `schema_validation` annotation as a comment to the top of your script. The logs should tell you if schema validation is taking place.

For example in [TypeScript](./meta-1_typescript_quickstart-index.md):

```ts
// schema_validation

export async function main(
	a: number,
	b: 'my' | 'enum',
	e = 'inferred type string from default arg',
	f = { nested: 'object' },
	g:
		| {
				label: 'Variant 1';
				foo: string;
		  }
		| {
				label: 'Variant 2';
				bar: number;
		  }
) {
	return { foo: a };
}
```

Here, if we were to pass a string to `a` instead of a number, or pass `"something else"` to `b` instead of `"my"` or `"enum"`, or even if the shape of `g` does not correspond to one of the OneOf variants, the job will fail.

This was an example in TypeScript but backend schema validation is available on all [languages](./meta-0_scripts_quickstart-index.md), in particular for [SQL safe interpolated arguments](./meta-5_sql_quickstart-index.md#safe-interpolated-arguments).

Note that this validation is not a fully JSON schema compliant. The checks you can expect are type and shape, required fields, strict enums. One thing that is not supported yet for instance is matching regex patterns on strings. When in doubt, it's best to test it out or provide your own checks.
