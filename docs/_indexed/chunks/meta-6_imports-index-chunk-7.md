---
doc_id: meta/6_imports/index
chunk_id: meta/6_imports/index#chunk-7
heading_path: ["Dependency management & imports", "Imports in PowerShell"]
chunk_type: code
tokens: 176
summary: "Imports in PowerShell"
---

## Imports in PowerShell

For PowerShell, imports are parsed when the script is run and modules are automatically installed if they are not found in the cache.

e.g.:

```powershell
Import-Module -Name MyModule
```

You can specify the version of the module to install by using the `-RequiredVersion` parameter.

e.g.:

```powershell
Import-Module -Name MyModule -RequiredVersion 1.0.0
```


### Private repository (Azure artifacts feed)

To setup an Azure artifacts feed as a private PowerShell repository, follow the [Azure documentation](https://learn.microsoft.com/en-us/azure/devops/artifacts/tutorials/private-powershell-library).

To configure the private repository in Windmill, set the Azure Artifacts url and Personal Access Token in the [Instance settings](./meta-18_instance_settings-index.md#registries).
Once configured, Windmill will check if imported modules are in the private repository (and not in cache) and will install them from there. It will fallback to the public repositories (e.g. PowerShell Gallery) if the module is not found.
