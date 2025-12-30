---
doc_id: meta/7_apps_quickstart/index
chunk_id: meta/7_apps_quickstart/index#chunk-1
heading_path: ["Apps quickstart"]
chunk_type: prose
tokens: 379
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import { useColorMode } from '@docusaurus/theme-common';

# Apps quickstart

> **Context**: import DocCard from '@site/src/components/DocCard'; import { useColorMode } from '@docusaurus/theme-common';

Welcome to the Apps quickstart! This page will provide you with the necessary knowledge to build your first applications in a matter of minutes.

If you're more into videos, you can check out our tutorial on the App editor:

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/lxqdncP8XR4"
	title="App editor Tutorial"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Although Windmill provides [auto-generated UIs to scripts and flows](./meta-6_auto_generated_uis-index.md), you can build your own internal applications designed to your needs. Either with our integrated [app editor](../../apps/0_app_editor/index.mdx), or by [importing your own React/Vue/Svelte apps](../../react_vue_svelte_apps/index.mdx).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
		color="orange"
	/>
	<DocCard
		title="App editor"
		description="Detailed section on Windmill's App editor"
		href="/docs/apps/app_editor"
		color="orange"
	/>
	<DocCard
		title="Example: E-commerce CRM app"
		description="Tutorial on how to build a CRM with Windmill."
		color="orange"
		hrefs="/docs/apps/app_e-commerce"
	/>
</div>

Windmill applications are customized UIs to interact with datasources (web, internal, data providers, etc). They are a great way to have non-technical users interact with custom-made workflows.

In short, what you need to remember about apps:

- They work on a what-you-see-is-what-you-get basis.
- You can connect apps and components to [datasources](../../integrations/0_integrations_on_windmill.mdx).
- Components can be empowered by Windmill [scripts](./meta-0_scripts_quickstart-index.md) and [flows](./meta-6_flows_quickstart-index.md).

:::tip

Follow our [detailed section](../../apps/0_app_editor/index.mdx) on the App editor for more information.

:::

To create your first app, you could pick one from our [Hub](https://hub.windmill.dev/apps) and fork it. Here, we're going to build our own app from scratch, step by step.

From <a href="https://app.windmill.dev/" rel="nofollow">Windmill</a>, click on `+ App`, and let's get started!
