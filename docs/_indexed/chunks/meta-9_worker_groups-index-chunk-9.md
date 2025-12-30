---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-9
heading_path: ["Workers and worker groups", "Worker scripts"]
chunk_type: prose
tokens: 344
summary: "Worker scripts"
---

## Worker scripts

Worker scripts provide methods to run bash scripts on workers at different stages of the worker lifecycle. There are two types of worker scripts: init scripts that run once at worker startup, and periodic scripts that run at regular intervals for ongoing maintenance.

Under the [Cloud plans & Self-Hosted Enterprise Edition](/pricing), both types of worker scripts can be configured from the Windmill UI in the worker group settings.

When adjustments are made in the Worker Management UI, the workers will shut down and are expected to be restarted by their supervisor (Docker or k8s).

### Init scripts

[Init scripts](./meta-8_preinstall_binaries-index.md#init-scripts) provide a method to pre-install binaries or set initial configurations without the need to modify the base image. This approach offers added convenience. Init scripts are executed at the beginning when the worker starts, ensuring that any necessary binaries or configurations are set up before the worker undertakes any other job.

<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
	<img
		src={require('../../advanced/8_preinstall_binaries/init_scripts.png').default}
		alt="Worker scripts Infographics"
		title="Worker scripts Infographics"
		width="70%"
	/>
</div>

<br />

The execution of init scripts is inspectable in the superadmin workspace, with Kind = All filter. The path of those executions are `init_script_{worker_name}`.

### Periodic scripts

Periodic scripts are bash scripts that run at regular intervals on workers, designed for ongoing maintenance tasks that need to be executed repeatedly during the worker's lifetime, with the **minimum interval settable between periodic script executions being 60 seconds**.


The execution of periodic scripts is inspectable in the superadmin workspace, with Kind = All filter. The path of those executions are `periodic_script_{worker_name}_{timestamp}`.
