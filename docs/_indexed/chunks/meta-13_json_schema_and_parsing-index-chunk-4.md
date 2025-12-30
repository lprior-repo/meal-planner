---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-4
heading_path: ["JSON schema and parsing", "Advanced settings"]
chunk_type: prose
tokens: 456
summary: "Advanced settings"
---

## Advanced settings

Main function's arguments can be given advanced settings that will affect the inputs' [auto-generated UI](./meta-6_auto_generated_uis-index.md) and JSON Schema.

Here is an example on how to define a [Python](./meta-2_python_quickstart-index.md) list as an enum of strings using the `Generated UI` menu.

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/advanced_parameters_enum.mp4"
/>

<br />

Each argument has the following settings:

- **Name**: the name of the argument (defined in the main Function).
- **Type**: the type of the argument (defined in the main Function): Integer, Number, String, Boolean, Array, Object, or Any.
- **Description**: the description of the argument.
- **Custom Title**: will be displayed in the UI instead of the field name.
- **Placeholder**: will be displayed in the input field when the field is empty. If not set, the default value (directly set from the script code) will be used. The placeholder is disabled depending on the field type, format, etc.
- **Field settings**: advanced settings depending on the type of the field.

Below is the list of advanced settings for each type of field:

| Type     | Advanced Configuration                                                                                                                                                                                                                                                         |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Integer  | Min and Max. Currency. Currency locale.                                                                                                                                                                                                                                        |
| Number   | Min and Max. Currency. Currency locale.                                                                                                                                                                                                                                        |
| String   | Min textarea rows. Disable variable picker. Is Password (will create a [variable](./meta-2_variables_and_secrets-index.md) when filled). Field settings: - File (base64) &#124; Enum &#124; Format: email, hostname, uri, uuid, ipv4, yaml, sql, date-time &#124; Pattern (Regex) |
| Boolean  | No advanced configuration for this type.                                                                                                                                                                                                                                       |
| Resource | [Resource type](./meta-3_resources_and_types-index.md).                                                                                                                                                                                                                           |
| Object   | Object properties, or a Template (path to a [`json_schema` resource](./meta-3_resources_and_types-index.md#json-schema-resources)) that contains a JSON schema with the properties.                                                                                                                                                   |
| Array    | - Items are strings &#124; Items are strings from an enum &#124; Items are objects (JSON) &#124; Items are numbers &#124; Items are bytes                                                                                                                                      |
| Any      | No advanced configuration for this type.                                                                                                                                                                                                                                       |

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Generated UI"
		description="Main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>
