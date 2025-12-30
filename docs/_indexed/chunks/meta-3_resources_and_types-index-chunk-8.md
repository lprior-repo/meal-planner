---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-8
heading_path: ["Resources and resource types", "Using resources"]
chunk_type: code
tokens: 703
summary: "Using resources"
---

## Using resources

Resources can be used [passed as script parameters](#passing-resources-as-parameters-to-scripts-preferred) or [directly fetched](#fetching-them-from-within-a-script-by-using-the-wmill-client-in-the-respective-language) within code.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/ggJQtzvqaqA"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

### Passing resources as parameters to scripts (preferred)

Resources can be passed using the [auto-generated UI](./meta-6_auto_generated_uis-index.md).

Provided you have the right permissions and the resource type exists in the workspace, you can access resource types from scripts, flows and apps using the Windmill client or [TypedDict](https://mypy.readthedocs.io/en/stable/typed_dict.html) in Python.

From the code editor's toolbar, click on the `+ Type` button and pick the right resource type. For example, to access the `u/user/my_postgresql` resource of the `posgtgresql` Resource Type we would create a script:

<Tabs className="unique-tabs">
<TabItem value="TypeScript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
type Postgresql = object;
// OR one can fully type it
type Postgresql = {
	host: string;
	port: number;
	user: string;
	dbname: string;
	sslmode: string;
	password: string;
	root_certificate_pem: string;
};

export async function main(postgres: Postgresql) {
	// Use Resource...
}
```

</TabItem>
<TabItem value="Python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
from typing import TypedDict

class postgresql(TypedDict):
    host: str
    port: int
    user: str
    dbname: str
    sslmode: str
    password: str
    root_certificate_pem: str

def main(selected_postgres: postgresql):
	# Use Resource...
```

</TabItem>
</Tabs>

<br />

And then select the Resource in the arguments section on the right:

![Select resource](../3_resources_and_types/select_resource.png.webp)

:::tip

You can also edit the Resource or even create a new one right from the Code
editor.

:::

All details on the [Add resources and variables to code editor](../../code_editor/add_variables_resources.mdx) page:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Add resources and variables to code editor"
		description="You can directly access Variables and Resources from the Code editor."
		href="/docs/code_editor/add_variables_resources"
	/>
</div>

### Fetching them from within a script by using the wmill client in the respective language

By clicking on `+ Resource`, you'll get to pick a resource from your workspace and be able to fetch it from within the script.

<Tabs className="unique-tabs">
<TabItem value="TypeScript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
wmill.getResource('u/user/foo');
```

</TabItem>
<TabItem value="Python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
wmill.get_resource("u/user/foo")
```

</TabItem>
<TabItem value="Go" label="Go" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```go
wmill.GetResource("u/user/foo")
```

</TabItem>
<TabItem value="Bash" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
curl -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/resources/get/u/user/foo" \
    | jq -r .value
```

</TabItem>
<TabItem value="PowerShell" label="PowerShell" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```powershell
$Headers = @{
  "Authorization" = "Bearer $Env:WM_TOKEN"
}
Invoke-RestMethod -Headers $Headers -Uri "$Env:BASE_INTERNAL_URL/api/w/$Env:WM_WORKSPACE/resources/get/u/user/foo"
```

</TabItem>
<TabItem value="Nu" label="Nu" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
get_resource u/user/foo
```

</TabItem>
</Tabs>

![Fetch resource](./fetch_resource.png.webp)

### Resources in Apps

Apps are [executed on behalf of publishers](../../apps/3_app-runnable-panel.mdx#policy) and by default cannot access viewer's resources.

If the resource passed here as a reference does not come from a static [Resource select](../../apps/4_app_configuration_settings/resource_select.mdx) component (which will be whitelisted by the auto-generated policy), you need to toggle "Resources from users allowed".

The toggle "Static resource select only / Resources from users allowed" can be found for each runnable input when the [source](../../apps/2_connecting_components/index.mdx) is an [eval](../../apps/3_app-runnable-panel.mdx#evals).

![Static resource select only / Resources from users allowed](../../assets/apps/0_app_editor/resources_from_users.png 'Static resource select only / Resources from users allowed')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="orange"
		title="Runnable editor"
		description="Learn how to create and configure Apps runnables."
	/>
</div>
