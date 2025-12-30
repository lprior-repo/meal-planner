---
doc_id: meta/1_typescript_quickstart/index
chunk_id: meta/1_typescript_quickstart/index#chunk-1
heading_path: ["TypeScript quickstart"]
chunk_type: prose
tokens: 486
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# TypeScript quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

In this quick start guide, we will write our first script in TypeScript. Windmill uses [Bun](https://bun.sh/), [Nodejs](#nodejs) and [Deno](https://deno.land/) as the available TypeScript runtimes.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/QRf8C8qF7CY"
	title="Scripts quickstart"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

This tutorial covers how to create a simple "Hello World" script in TypeScript through Windmill web IDE, with the standard mode of handling dependencies in TypeScript (Lockfile per script inferred from imports). See the dedicated pages to [develop scripts locally](./meta-4_local_development-index.md) and other methods of [handling dependencies in TypeScript](./meta-14_dependencies_in_typescript-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
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

- [Code](#code): for TypeScript scripts, it must have at least a main function.
- [Settings](#settings): settings & metadata about the Script such as its path, summary, description, [JSON Schema](./meta-13_json_schema_and_parsing-index.md) of its inputs (inferred from its signature).

When stored in a code repository, those 2 parts are stored separately at `<path>.ts` and `<path>.script.yaml`.

[This](https://hub.windmill.dev/scripts/slack/1284/send-message-to-channel-slack) is a simple example of a script built in TypeScript with Windmill:

```ts
import { WebClient } from '@slack/web-api';

type Slack = {
	token: string;
};

export async function main(slack: Slack, channel: string, message: string): Promise<void> {
	// Initialize the Slack WebClient with the token from the Slack resource
	const web = new WebClient(slack.token);

	// Use the chat.postMessage method from the Slack WebClient to send a message
	await web.chat.postMessage({
		channel: channel,
		text: message
	});
}
```

In this quick start guide, we'll create a script that greets the operator running it.

From the Home page, click `+Script`. This will take you to the first step of script creation: [Metadata](./tutorial-script_editor-settings.md#metadata).
