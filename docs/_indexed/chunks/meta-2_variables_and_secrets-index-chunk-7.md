---
doc_id: meta/2_variables_and_secrets/index
chunk_id: meta/2_variables_and_secrets/index#chunk-7
heading_path: ["Variables and secrets", "Accessing a variable from a script"]
chunk_type: code
tokens: 429
summary: "Accessing a variable from a script"
---

## Accessing a variable from a script

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Add resources and variables to code editor"
		description="You can directly access Variables and Resources from the Code editor."
		href="/docs/code_editor/add_variables_resources"
	/>
</div>

### Accessing contextual variables from a script

See the `Contextual` tab on the <a href="https://app.windmill.dev/variables" rel="nofollow">Variable page</a> for the list of reserved variables and what they are used for.

You can use them in a Script by clicking on "+Context Var":

![Contextual variable](../2_variables_and_secrets/context_variables.png.webp)

Reserved variables are passed to the job as environment variables. For example, the ephemeral token is passed as `WM_TOKEN`.

### Accessing user-defined variables from a script

There are 2 main ways variables are used within scripts:

#### Passing variables as parameters to scripts

Variables can be passed as parameters of the script, using the UI-based variable picker. Underneath, the variable is passed as a string of the form: `$var:<variable_path>` and replaced by the worker at time of execution of the script by fetching the value with the job's permissions. So the job will fail if the job's permissions inherited from the caller do not allow access to the variable. This is the same mechanism used for resource, but they use `$res:` instead of `$var:`.

![Select Variable](./select_variable.png.webp)

#### Fetching them from within a script by using the wmill client in the respective language

By clicking on `+ Variable`, you'll get to pick a variable from your workspace and be able to fetch it from within the script.

![Fetch Variable](./fetch_variable.png.webp)

TypeScript:

```typescript
wmill.getVariable('u/user/foo');
```

Python:

```python
wmill.get_variable("u/user/foo")
```

Go:

```go
wmill.GetVariable("u/user/foo")
```

Bash:

```bash
curl -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/variables/get/u/user/foo" \
    | jq -r .value
```

PowerShell:

```powershell
$Headers = @{
  "Authorization" = "Bearer $Env:WM_TOKEN"
}
Invoke-RestMethod -Headers $Headers -Uri "$Env:BASE_INTERNAL_URL/api/w/$Env:WM_WORKSPACE/variables/get/u/user/foo"
```

Nu:

```python
get_variable u/user/foo
```

Examples in bash and PowerShell showcase well how it works under the hood: It fetches the secret from the API using the job's permissions through the ephemeral token passed as an environment variable to the job.
