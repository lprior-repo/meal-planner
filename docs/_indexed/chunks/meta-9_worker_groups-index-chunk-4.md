---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-4
heading_path: ["Workers and worker groups", "Create worker group config"]
chunk_type: prose
tokens: 235
summary: "Create worker group config"
---

## Create worker group config

<img
	src={require('./wg_config_infographics.png').default}
	alt="Worker group config infographics"
	title="Worker group config infographics"
	width="75%"
/>

<br />

In the [Cloud plans & Self-Hosted Enterprise Edition](/pricing), workers can be commonly managed based on the group they are in, from the UI. Specifically, you can group the workers into worker groups, groups for which you can manage the tags they listen to (queue), assignment to a single script, or the worker init scripts, from the UI.

> In [Community Edition](/pricing) Workers can still have their WORKER_TAGS passed as env.

<br />

Pick "New worker group config" and just write the name of your worker group.

![New worker group config](../../../static/images/new_worker_group_config.png 'New worker group config')

You can then configure it directly from the UI.

![Worker group config](../../../static/images/worker_group_config.png 'Worker group config')

<br />

Examples of configurations include:

1. [Assign different jobs to specific worker groups](#set-tags-to-assign-specific-queues) by giving them tags.
2. [Set an init or periodic script](#worker-scripts) that will run at the start of the workers or periodically (e.g. to pre-install binaries).
3. [Dedicate your worker to a specific script or flow](#dedicated-workers--high-throughput) for high throughput.
