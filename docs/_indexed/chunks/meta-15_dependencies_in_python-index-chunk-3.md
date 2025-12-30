---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-3
heading_path: ["Dependencies in Python", "Lockfile per script inferred from a requirements.txt"]
chunk_type: prose
tokens: 405
summary: "Lockfile per script inferred from a requirements.txt"
---

## Lockfile per script inferred from a requirements.txt

Although Windmill can [automatically resolve imports](#lockfile-per-script-inferred-from-imports-standard). It is possible to override the dependencies by providing a `requirements.txt` file in the same directory as the script as you would do in a standard Python project, building and maintaining a requirements.txt to declare dependencies.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/T8jMjpNvC2g"
	title="Override Inferred Dependencies with Custom Dependency Files"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

When doing [`wmill script generate-metadata`](./concept-3_cli-script.md#re-generating-a-script-metadata-file), if a requirements.txt is discovered, the closest one will be used as source-of-truth instead of being discovered from the imports in the script directly to generate the lockfile from the server.

You can write those requirements.txt manually or through a standard `pip install package_name`.

Several requirements.txt files can therefore coexist, each having authority over the scripts closest to it:

```text
└── windmill_folder/
    ├── requirements.txt
    ├── f/foo/
    │   ├── requirements.txt
    │   ├── script1.py
    │   ├── # script1.py will use the dependencies from windmill_folder/f/foo/requirements.txt
    │   └── /bar/
    │       ├── requirements.txt
    │       ├── script2.py
    │       └── # script2.py will use the dependencies from windmill_folder/f/foo/bar/requirements.txt
    └── f/baz/
        ├── script3.py
        └── # script3.py will use the dependencies from windmill_folder/requirements.txt
```

The Windmill [VS Code extension](./meta-1_vscode-extension-index.md) has a toggle "Infer lockfile" / "Use current lockfile".

With this toggle, you can choose to use the metadata lockfile (derived from requirements.txt after `wmill script generate-metadata`) instead of inferring them directly from the script.

![Toggle Lockfile](../../cli_local_dev/1_vscode-extension/toggle_lockfile.png 'Toggle Lockfile')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop locally, push to git and deploy automatically to Windmill."
		href="/docs/advanced/local_development"
	/>
  <DocCard
		title="Command-line interface (CLI)"
		description="The Windmill CLI, `wmill` allows you to interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
	<DocCard
		title="VS Code extension"
		description="Build scripts and flows in the comfort of your VS Code editor, while leveraging Windmill UIs for test & flows edition."
		href="/docs/cli_local_dev/vscode-extension"
	/>
</div>
