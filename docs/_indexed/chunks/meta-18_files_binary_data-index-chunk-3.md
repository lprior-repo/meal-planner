---
doc_id: meta/18_files_binary_data/index
chunk_id: meta/18_files_binary_data/index#chunk-3
heading_path: ["Handling files and binary data", "Base64 encoded strings"]
chunk_type: prose
tokens: 357
summary: "Base64 encoded strings"
---

## Base64 encoded strings

Base64 strings can also be used, but the main difficulty is that those Base64 strings can not be distinguished from normal strings.
Hence, the interpretation of those Base64 encoded strings is either done depending on the context,
or by pre-fixing those strings with the [`<data specifier:>`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types).

In explicit contexts, when the JSON schema specifies that a property represents Base64-encoded data:

```yaml
foo:
    type: string
    format: base64
```

If necessary, Windmill automatically converts it to the corresponding binary type in the corresponding
language as defined in the [schema](./meta-13_json_schema_and_parsing-index.md).
In Python, it will be converted to the `bytes` type (for example `def main (input_file: bytes):`). In TypeScript, they are simply represented as strings.

In ambiguous situations (file ino) where the context does not provide clear indications,
it is necessary to precede the binary data with the `data:base64` [encoding declaration](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs).

In the app editor, in some cases when there is no ambiguity, the data prefix is optional.

Base64 encoded strings are used in:

- File input component in the app editor: files uploaded are converted and returned as a Base64 encoded string.
- Download button: the source to be downloaded must be in Base64 format.
- File inputs to run scripts must be typed into the [JSON](./meta-13_json_schema_and_parsing-index.md) `string, encodingFormat: base64` (python: `bytes`, Deno: `wmill.Base64`).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="File input Component"
		description="The file input allows users to drop files into the app."
		href="/docs/apps/app_configuration_settings/app_component_library#file-input"
	/>
	<DocCard
		title="Download button"
		description="The download button component allows you to download a file."
		href="/docs/apps/app_configuration_settings/app_component_library#download-button"
	/>
	<DocCard
		title="JSON schema and parsing"
		description="Windmill leverages the JSON Schema to define the structure and validation rules for JSON data."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>
