---
doc_id: meta/8_php_quickstart/index
chunk_id: meta/8_php_quickstart/index#chunk-3
heading_path: ["PHP quickstart", "Code"]
chunk_type: code
tokens: 468
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for php](./editor_php.png "Editor for php")

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

As we picked `php` for this example, Windmill provided some php
boilerplate. Let's take a look:

```php
<?php

// remove the first // of the following lines to specify packages to install using composer
// // require:
// // monolog/monolog@3.6.0
// // stripe/stripe-php

function main(
	// Postgresql $a,
  // array $b,
  // object $c,
	int $d = 123,
	string $e = "default value",
	float $f = 3.5,
  bool $g = true,
) {
	return $d;
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

Packages can be installed using composer. Just uncomment the `require` lines and add the packages you need. Windmill will install them for you:

```php
<?php

// require:
// monolog/monolog@3.6.0
// stripe/stripe-php

function main(
	// Postgresql $a,
  // array $b,
  // object $c,
	int $d = 123,
	string $e = "default value",
	float $f = 3.5,
  bool $g = true,
) {
	return $d;
}

```
