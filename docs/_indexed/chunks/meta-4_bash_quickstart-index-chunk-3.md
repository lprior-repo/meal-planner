---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-3
heading_path: ["TypeScript quickstart", "arguments of the form X=\"$I\" are parsed as parameters X of type string"]
chunk_type: code
tokens: 237
summary: "arguments of the form X=\"$I\" are parsed as parameters X of type string"
---

## arguments of the form X="$I" are parsed as parameters X of type string
url="${1:-default value}"

status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)

if [[ $status_code == 2* ]] || [[ $status_code == 3* ]]; then
  echo "The URL is reachable!"
else
  echo "The URL is not reachable."
fi
```

</TabItem>
<TabItem value="powershell" label="PowerShell" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```powershell
param($url = "default value")

$status_code = (Invoke-WebRequest -Uri $url -Method Get).StatusCode

if ($status_code -like "2*" -or $status_code -like "3*") {
    Write-Host "The URL is reachable!"
} else {
    Write-Host "The URL is not reachable."
}
```
</TabItem>
<TabItem value="nu" label="Nu" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
def main [
  url: string = "default value"
] {
  try {
    # Nu will throw an error automatically if request fails
    http get $url
    echo "The URL is reachable!"
  } catch {
    echo "The URL is not reachable."
  }
}
```

</TabItem>
</Tabs>

In this quick start guide, we'll create a script that greets the operator running it.

From the Home page, click `+Script`. This will take you to the first step of script creation: [Metadata](./tutorial-script_editor-settings.md#metadata).
