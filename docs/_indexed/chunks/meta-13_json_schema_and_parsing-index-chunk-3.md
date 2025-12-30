---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-3
heading_path: ["JSON schema and parsing", "JSON Schema in Windmill"]
chunk_type: code
tokens: 1099
summary: "JSON Schema in Windmill"
---

## JSON Schema in Windmill

In Windmill, the JSON Schema is used in various contexts, such as defining the input specification for scripts and flows, and specifying resource types.

Below is a simplified spec of a JSON Schema. See [here for its full spec](https://json-schema.org/). Windmill is compatible with the [2020-12 version](https://json-schema.org/draft/2020-12/schema). It is not compatible with its most advanced features yet.

```json
{
	"$schema": "https://json-schema.org/draft/2020-12/schema",
	"type": "object",
	"properties": {
		"your_name": {
			"description": "The name to hello world to",
			"type": "string"
		},
		"your_nickname": {
			"description": "If you prefer a nickname, that's fine too",
			"type": "string"
		}
	},
	"required": []
}
```

Where the `properties` field contains a dictionary of arguments, and `required` is the list of all the mandatory arguments.

The property names need to match the arguments declared by the main function, in our example `your_name` and `your_nickname`. There is a lot you can do with arguments, types, and validation, but to keep it short:

- Arguments can specify a type `integer`, `number`, `string`, `boolean`, `object`, `array` or `any`. The user's input will be validated against that type.
- One can further constraint the type by having the string following a RegEx or pattern, or the object to be of a specific [Resource Type](./meta-3_resources_and_types-index.md).
- Arguments can be made mandatory by adding them to the `required` list. In that case, the generated UI will check that user input provides required arguments.
- Each argument can have a description and default fields, that will appear in the generated UI.
- Some types have advanced settings.

### Script parameters to JSON Schema

Scripts in Windmill have input parameters defined by a JSON Schema, where each parameter in the main function of a script corresponds to a field in the JSON Schema. This one-to-one correspondence ensures that the name of the argument becomes the name of the property, and most primitive types in Python and TypeScript have a corresponding primitive type in JSON and JSON Schema. During script execution, the parameters and their types are validated against the JSON Schema, ensuring that the input adheres to the expected format.

In [Python](./meta-2_python_quickstart-index.md):

| Python                           | JSON Schema                      |
| -------------------------------- | -------------------------------- |
| `str`                            | `string`                         |
| `float`                          | `number`                         |
| `Literal["a", "b"]`              | `string` with enums: "a", "b"    |
| `int`                            | `integer`                        |
| `bool`                           | `boolean`                        |
| `dict`                           | `object`                         |
| `list`                           | `any[]`                          |
| `List[str]`                      | `string[]`                       |
| `bytes`                          | `string, encodingFormat: base64` |
| `datetime`                       | `str, format: date-time`         |
| `_`                              | `any`                            |
| [DynSelect_foo](#dynamic-select) | `dynselect-<name>`               |

In [Deno, Bun](./meta-1_typescript_quickstart-index.md), [REST](./meta-6_rest_grapqhql_quickstart-index.md):

| TypeScript                       | JSON Schema                   |
| -------------------------------- | ----------------------------- |
| `string`                         | `string`                      |
| `"a" \| "b"`                     | `string` with enums: "a", "b" |
| `object`                         | `object`                      |
| `boolean`                        | `boolean`                     |
| `bigint`                         | `int`                         |
| `number`                         | `number`                      |
| `string[]`                       | `string[]`                    |
| `("foo" \| "bar")[]`             | `enum[]`                      |
| [oneOf](#oneof)                  | `object`                      |
| [DynSelect_foo](#dynamic-select) | `dynselect-<name>`            |

However in TypeScript there also some special types that are specific to Windmill.
They are as follows:

| Windmill         | JSON Schema                                  |
| ---------------- | -------------------------------------------- |
| `wmill.Base64`   | `string`, encoding$$Format: `base64`         |
| `wmill.Email`    | `string`, format: `email`                    |
| `wmill.Sql`      | `string`, format: `sql`                      |
| `<ResourceType>` | `object`, format: `resource-{resource_type}` |

The `<ResourceType>` is any type that has a matching resource_type in the workspace (more details [here](./meta-3_resources_and_types-index.md#using-resources)). Note that the CamelCase of the type is converted to the snake_case.
`Base64` and `Email` are actually a type alias for `string`, and `Resource` is a
type alias for an `object`. They are purely type hints for the Windmill parser.

The `sql` format is specific to Windmill and replaces the normal text field with
a monaco editor with SQL support.

:::info

The equivalent of the type `Postgresql` in Python is the
following:

```python
my_resource_type = dict

def main(x: my_resource_type):
  ...
```

:::

The JSON Schema of a script's arguments is visible and can be modified from the [`Generated UI`](./meta-6_auto_generated_uis-index.md) menu.

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schema_script.mp4"
/>

### Flows parameters and JSON Schema

Flows in Windmill have input parameters defined by a JSON Schema. Each argument of the [`Flow Input`](./tutorial-flows-3-editor-components.md#flow-inputs) section corresponds to a field in the JSON Schema. The parameters and their types are validated against the JSON Schema during flow execution.

The JSON Schema of a script's arguments can be modified in the `Flow Input` menu. The schema is visible from the `Export / OpenFlow` section, in particular the "Input Schema" tab.

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schema_flows.mp4"
/>

<br />

Inline scripts of flows & apps use an autogenerated JSON Schema that is implicitly used by the frontend.

### Resource types and JSON Schema

Resource types in Windmill are associated with JSON Schemas. A resource type defines the structure and constraints of a resource object. JSON Schema is used to validate the properties and values of a resource object against the specified resource type.

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schema_rt.mp4"
/>
