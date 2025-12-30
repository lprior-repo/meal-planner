---
doc_id: meta/8_preinstall_binaries/index
chunk_id: meta/8_preinstall_binaries/index#chunk-6
heading_path: ["Preinstall binaries", "Init scripts"]
chunk_type: code
tokens: 503
summary: "Init scripts"
---

## Init scripts

Init scripts provide a method to pre-install binaries or set initial configurations without the need to modify the base image. This approach offers added convenience.
Init scripts are executed at the beginning when the worker starts, ensuring that any necessary binaries or configurations are set up before the worker undertakes any other job.

Init scripts are available only on [self-hosting and enterprise edition](/pricing) on private clusters.

<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
	<img
		src={require('./init_scripts.png.webp').default}
		alt="Init scripts Infographics"
		title="Init scripts Infographics"
		width="70%"
	/>
</div>

<br />

Any scripts are set from the [Worker Management UI](../../misc/11_worker_group_management_ui/index.mdx), at the worker group level. Any script content specified in `INIT_SCRIPT` will be executed at the beginning when each worker of the worker group starts.

When adjustments are made in the [Worker Management UI](../../misc/11_worker_group_management_ui/index.mdx), the workers will shut down and are expected to be restarted by their supervisor (Docker or k8s).

The execution of Init scripts is inspectable in the superadmin workspace, with `Kind = All` filter. The path of those executions are `init_script_{worker_name}`.

![Worker Group edit config](../../core_concepts/9_worker_groups/worker_group_ui.png.webp)

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/2o28HMF1Cnk"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

:::info
Windmill does not pre-install pip or python directly in the base image as system binaries, instead it uses uv and uv manages the python versions (including pre-installing one for performance).

To pre-install packages using pip, you will want to use uv, in particular the [uv tool install](https://docs.astral.sh/uv/concepts/tools/#tools-directory) command. The bin path of uv tool is already in the PATH of the worker, so your jobs will be able to run directly binaries installed in such way.

To have packages be available for import, place them in `/tmp/windmill/cache/python_x_y/global-site-packages` where x_y is the python version intended. For python 3.11.*, the path would be `/tmp/windmill/cache/python_3_11/global-site-packages`.

:::

### Example: Installing Pandas

```bash
uv pip install --system pandas --target /tmp/windmill/cache/python_3_11/global-site-packages
```

### Example: Installing Playwright (via uv)

```bash
uv tool install playwright
playwright install
playwright install-deps
```

More at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="Worker groups management UI"
		description="On Enterpris Edition, worker groups can be managed through Windmill UI."
		href="/docs/misc/worker_group_management_ui"
	/>
</div>
