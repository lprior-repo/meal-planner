---
doc_id: meta/2_python_quickstart/index
chunk_id: meta/2_python_quickstart/index#chunk-6
heading_path: ["Python quickstart", "you can use typed resources by doing a type alias to dict"]
chunk_type: code
tokens: 495
summary: "you can use typed resources by doing a type alias to dict"
---

## you can use typed resources by doing a type alias to dict
#postgresql = dict

def main(
    no_default: str,
    #db: postgresql,
    name="Nicolas Bourbaki",
    age=42,
    obj: dict = {"even": "dicts"},
    l: list = ["or", "lists!"],
    file_: bytes = bytes(0),
):

    print(f"Hello World and a warm welcome especially to {name}")
    print("and its acolytes..", age, obj, l, len(file_))

    # retrieve variables, resources, states using the wmill client
    try:
        secret = wmill.get_variable("f/examples/secret")
    except:
        secret = "No secret yet at f/examples/secret !"
    print(f"The variable at `f/examples/secret`: {secret}")

    # Get last state of this script execution by the same trigger/user
    last_state = wmill.get_state()
    new_state = {"foo": 42} if last_state is None else last_state
    new_state["foo"] += 1
    wmill.set_state(new_state)

    # fetch context variables
    user = os.environ.get("WM_USERNAME")

    # return value is converted to JSON
    return {"splitted": name.split(), "user": user, "state": new_state}
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

The last import line imports the [Windmill client](./ops-2_clients-python-client.md), which is needed for example to access
[variables](./meta-2_variables_and_secrets-index.md) or
[resources](./meta-3_resources_and_types-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependencies in Python"
		description="How to manage dependencies in Python scripts."
		href="/docs/advanced/dependencies_in_python"
	/>
	<DocCard
		title="Python client"
		description="The Python client library for Windmill provides a convenient way to interact with the Windmill platform's API from within your script jobs."
		href="/docs/advanced/clients/python_client"
	/>
</div>

Back to our Hello World. We can clean up unused import statements, change the
main to take in the user's name. Let's also return the `name`, maybe we can use
this later if we use this Script within a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) and need to pass its result on.

```py
def main(name: str):
  print("Hello world. Oh, it's you {}? Greetings!".format(name))
  return name
```
