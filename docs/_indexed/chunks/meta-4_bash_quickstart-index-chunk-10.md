---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-10
heading_path: ["TypeScript quickstart", "the last line of the stdout is the return value"]
chunk_type: code
tokens: 214
summary: "the last line of the stdout is the return value"
---

## the last line of the stdout is the return value
Write-Output "Hello $Msg"
```

In PowerShell, the arguments are inferred from the param instruction. It has to be first in the script.
Arguments can be of type `string`, `int`/`long`/`double`/`decimal`/`single`, `PSCustomObject` (parsed from JSON), `datetime`, `bool` and array of these types.
Default arguments can be specified using the following syntax: `$argument_name = "Its default value"`.

The last line of the output, here `Write-Output "Hello $Msg"`, is the return value, which might be useful if the script is used in a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) to pass its result on.

### Nu

Unlike `Bash` and `PowerShell`, `Nu` requires main function and all arguments should defined in signature.
It supports typed, optional and default arguments.

<Tabs className="unique-tabs">
<TabItem value="simple" label="Simple" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
def main [ msg, dflt = "default value", nb: number = 3 ] {
	echo $"Hello ($msg)"
}
```
</TabItem>
<TabItem value="complete" label="Complete" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
use std assert
