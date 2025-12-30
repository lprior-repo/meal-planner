---
doc_id: meta/1_vscode-extension/index
chunk_id: meta/1_vscode-extension/index#chunk-3
heading_path: ["VS Code extension", "Actions"]
chunk_type: prose
tokens: 366
summary: "Actions"
---

## Actions

The preview & run will work for any script meeting the specific language requirements (main function, imports) and being named with the dedicated file extension (.py, .go etc.). For scripts in Bun, name the file \[name\].bun.ts, ".ts" being by default Deno.

The extension will split your screen and display a panel. That panel will update automatically based on the edited document on the left.

- When editing a script (or a flow step), you see the script [preview UI](./meta-6_auto_generated_uis-index.md) with the [auto-inference of the parameters](./meta-13_json_schema_and_parsing-index.md).
- When editing a flow YAML, you see the flow builder and the flow [test UI](./ops-flows-18-test-flows.md).

In particular:

### Test scripts, flows and flows steps

Once you have your scripts and flows locally (either pulled from a remote workspace or created from scratch), you can test them directly from VS Code.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	src="/videos/vs_code_tour.mp4"
/>

### Update UI from YAML

Editing the YAML definition of a flow instantly updates the rendered graph

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	src="/videos/ui_to_yaml.mp4"
/>

### Update YAML from UI

Editing the flow from the UI immediately modifies the YAML definition

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	src="/videos/yaml_to_ui.mp4"
/>

### Flow YAML validation

The VS Code extension includes syntax validation for flow.yaml files, making it easier to spot mistakes and ensure your flows are properly formatted before testing or deployment.

### Infer lockfile or use current lockfile

With this toggle, you can choose to use the metadata lockfile ([derived from](./concept-3_cli-script.md#packagejson--requirementstxt) package.json or requirements.txt after [`wmill script generate-metadata`](./concept-3_cli-script.md#re-generating-a-script-metadata-file)) instead of inferring them directly from the script.

![Toggle Lockfile](./toggle_lockfile.png 'Toggle Lockfile')

To learn more about lockfile, see [Local development](./meta-4_local_development-index.md).
