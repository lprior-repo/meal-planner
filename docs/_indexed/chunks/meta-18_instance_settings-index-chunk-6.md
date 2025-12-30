---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-6
heading_path: ["Instance settings", "Registries"]
chunk_type: prose
tokens: 171
summary: "Registries"
---

## Registries

Add private registries for [UV](https://pypi.org/), [Bun](https://bun.sh/), [npm](https://www.npmjs.com/), [Nuget](https://www.nuget.org/), and [PowerShell](https://learn.microsoft.com/en-us/azure/devops/artifacts/tutorials/private-powershell-library).

These settings are only available on [Enterprise Edition](/pricing).

![Registries](./registries.png "Registries")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a requirements.txt directly."
		href="/docs/advanced/imports"
	/>
	<DocCard
		title="Dependencies in Python"
		description="How to manage dependencies in Python scripts."
		href="/docs/advanced/dependencies_in_python"
	/>
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
	/>
</div>

### UV index url

Add private registry for python.

### UV extra index url

Add private extra private registry for python.

### Npm config registry

Add private NPM registry.

### Bunfig install scopes

Add private scoped registries for Bun, See: https://bun.sh/docs/install/registries.

### Nuget config

Write a nuget.config file to set custom/private package sources and credentials.
