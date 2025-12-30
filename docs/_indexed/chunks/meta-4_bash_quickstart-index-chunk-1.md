---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-1
heading_path: ["TypeScript quickstart"]
chunk_type: prose
tokens: 310
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Bash / PowerShell / Nu quickstart

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In this quick start guide, we will write our first script in Bash, PowerShell or Nu.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/bash_quickstart.mp4"
/>

<br />

This tutorial covers how to create a simple script through Windmill web IDE. See the dedicated page to [develop scripts locally](./meta-4_local_development-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
</div>

Scripts are the basic building blocks in Windmill. They can be [run and scheduled](./meta-8_triggers-index.md) as standalone, chained together to create [Flows](./tutorial-flows-1-flow-editor.md) or displayed with a personalized User Interface as [Apps](./meta-7_apps_quickstart-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script editor"
		description="All the details on scripts."
		href="/docs/script_editor"
	/>
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

Scripts consist of 2 parts:

- [Code](#code).
- [Settings](#settings): settings & metadata about the Script such as its path, summary, description, [JSON Schema](./meta-13_json_schema_and_parsing-index.md) of its inputs (inferred from its signature).

When stored in a code repository, those 2 parts are stored separately at `<path>.sh` and `<path>.script.yaml`.

Below is a simple example of a script built in Bash/Powershell/Nu with Windmill:

<Tabs className="unique-tabs">
<TabItem value="bash" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
