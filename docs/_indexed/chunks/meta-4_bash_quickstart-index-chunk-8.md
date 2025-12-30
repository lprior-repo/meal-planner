---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-8
heading_path: ["TypeScript quickstart", "the last line of the stdout is the return value"]
chunk_type: prose
tokens: 132
summary: "the last line of the stdout is the return value"
---

## the last line of the stdout is the return value
echo "Hello $msg"
```

In Bash, the arguments are inferred from the arguments requiring a \$1, \$2, \$3. Default arguments can be specified using the syntax above: `dflt="${2:-default value}"`.

The last line of the output, here `echo "Hello $msg"`, is the return value, which might be useful if the script is used in a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) to pass its result on.

### PowerShell

As we picked `PowerShell` for this example, Windmill provided some PowerShell
boilerplate. Let's take a look:

```powershell
param($Msg, [string[]]$Names, [PSCustomObject]$Obj, $Dflt = "default value", [int]$Nb = 3)
