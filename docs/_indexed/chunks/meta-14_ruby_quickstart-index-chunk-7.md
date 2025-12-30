---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-7
heading_path: ["Ruby quickstart", "See here for more info: https://www.windmill.dev/docs/advanced/dependencies_in_ruby"]
chunk_type: code
tokens: 436
summary: "See here for more info: https://www.windmill.dev/docs/advanced/dependencies_in_ruby"
---

## See here for more info: https://www.windmill.dev/docs/advanced/dependencies_in_ruby

def main(
  name = "Nicolas Bourbaki",
  age = 42,
  obj = { "even" => "hashes" },
  l = ["or", "arrays!"]
)
  puts "Hello World and a warm welcome especially to #{name}"
  puts "and its acolytes.. #{age} #{obj} #{l}"

  # retrieve variables, resources using built-in methods
  begin
		# Imported from windmill mini client
    secret = get_variable("f/examples/secret")
  rescue => e
    secret = "No secret yet at f/examples/secret!"
  end
  puts "The variable at `f/examples/secret`: #{secret}"

  # fetch context variables
  user = ENV['WM_USERNAME']

  # return value is converted to JSON
  return {
    "splitted" => name.split,
    "user" => user,
    "message" => "Hello from Ruby!"
  }
end
```

In Windmill, scripts can optionally have a `main` function that will be the script's
entrypoint. If no main function is defined, the entire script will be executed. There are a few important things to note about the `main` function:

- The main arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Default values are used to infer argument types and generate the UI form. String defaults create string inputs, numeric defaults create number inputs, hash/array defaults create appropriate JSON inputs, etc.
- You can customize the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

The first import line imports the Windmill Ruby client, which provides access to built-in methods for accessing
[variables](./meta-2_variables_and_secrets-index.md) and
[resources](./meta-3_resources_and_types-index.md).

Back to our Hello World. We can clean up the boilerplate, change the
main to take in the user's name. Let's also return the `name`, maybe we can use
this later if we use this Script within a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) and need to pass its result on.

```ruby
def main(name = "World")
  puts "Hello #{name}! Greetings from Ruby!"
  return name
end
```
