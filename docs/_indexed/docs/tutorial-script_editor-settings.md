---
id: tutorial/script_editor/settings
title: "Settings"
category: tutorial
tags: ["settings", "script_editor", "beginner", "tutorial"]
---

import DocCard from '@site/src/components/DocCard';

# Settings

> **Context**: import DocCard from '@site/src/components/DocCard';

Each script has settings associated with it, enabling it to be defined and configured in depth.

![Script settings](../../static/images/script_languages.png 'Script settings')

## Metadata

Metadata is used to define the script's path, summary, description, language and kind.

### Summary

Summary (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.

It can be pre-filled automatically using [Windmill AI](./meta-22_ai_generation-index.md):

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/summary_compilot.mp4"
/>

### Path

Path is the Script's unique identifier that consists of the [script's owner](./meta-16_roles_and_permissions-index.md#permissions-and-access-control), and the script's name.
The owner can be either a user, or a group of users ([folder](./meta-8_groups_and_folders-index.md#folders)).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
	/>
	<DocCard
		title="Groups and folders"
		description="Groups and folders enable efficient permission management by grouping users with similar access levels."
		href="/docs/core_concepts/groups_and_folders"
	/>
</div>

### Description

This is where you can give instructions to users on how to run your Script. It supports markdown.

### Language

Language of the script. Windmill supports:
- [TypeScript](./meta-1_typescript_quickstart-index.md) (Bun & Deno)
- [Python](./meta-2_python_quickstart-index.md)
- [Go](./meta-3_go_quickstart-index.md)
- [Bash & Powershell & Nu](./meta-4_bash_quickstart-index.md)
- [SQL](./meta-5_sql_quickstart-index.md) (PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake)
- [Rest & GraphQL](./meta-6_rest_grapqhql_quickstart-index.md)
- [Docker](./meta-7_docker_quickstart-index.md)

You can configure the languages that are visible and their order.

The setting applies to scripts, flows and apps and is global to all users within a workspace but only configurable by [admins](./meta-16_roles_and_permissions-index.md#admin).

![Configurable Default Languages](../assets/script_editor/configurable-languages.png 'Configurable Default Languages')

### Script kind

You can attach additional functionalities to Scripts by specializing them into specific Script kinds (Actions, Trigger, Approval, Error handler, Preprocessor).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script kind"
		description="You can attach additional functionalities to Scripts by specializing them into specific Script kinds."
		href="/docs/script_editor/script_kinds"
	/>
</div>

## Runtime

Runtime settings allow you to configure how your script is executed.

![Script runtime](../../static/images/script_runtime.png "Script runtime")

### Concurrency limits

The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Concurrency limit"
		description="The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows."
		href="/docs/script_editor/concurrency_limit"
	/>
</div>

### Debouncing

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Job debouncing"
		description="Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics."
		href="/docs/core_concepts/job_debouncing"
	/>
</div>

### Worker group tag

Scripts can be assigned custom [worker groups](./meta-9_worker_groups-index.md) for efficient execution on different machines with varying specifications.

For scripts saved on the script editor, select the corresponding worker group tag in the [settings](./tutorial-script_editor-settings.md) section.

![Worker group tag](../core_concepts/9_worker_groups/select_script_builder.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Worker Groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
</div>

### Cache

Caching a script step means caching the results for a certain duration. If the script is triggered with the same inputs during the given duration, it will return the cached result.

### Timeout

Add a custom timeout for this script, for a given duration.

If enabled to execution will be stopped after the timeout.

### Perpetual script

Perpetual scripts restart upon ending unless canceled.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Running services with perpetual scripts"
		description="Perpetual scripts restart upon ending unless canceled."
		href="/docs/script_editor/perpetual_scripts"
	/>
</div>

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/5uw3JWiIFp0"
	title="Running services with perpetual scripts"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

### Dedicated workers

In this mode, the script is meant to be run on [dedicated workers](./meta-9_worker_groups-index.md) that run the script at native speed. Can reach >1500rps per dedicated worker. Only available on enterprise edition and for Python3, Deno and Bun. For other languages, the efficiency is already on par with deidcated workers since they do not spawn a full runtime.

### Delete after use

Delete [logs](./meta-14_audit_logs-index.md), arguments and results after use.

:::warning

This settings ONLY applies to [synchronous webhooks](./meta-4_webhooks-index.md#synchronous) or when the script is used within a [flow](./tutorial-flows-1-flow-editor.md). If used individually, this script must be triggered using a synchronous endpoint to have the desired effect.
<br/>
The logs, arguments and results of the job will be completely deleted from Windmill once it is complete and the result has been returned.
<br/>
The deletion is irreversible.

:::

### High priority script

Jobs within a same job queue can be given a [priority](./meta-20_jobs-index.md#high-priority-jobs) between 1 and 100. Jobs with a higher priority value will be given precedence over jobs with a lower priority value in the job queue.

### Runs visibility

When this [option](./meta-5_monitor_past_and_future_runs-index.md#invisible-runs) is enabled, manual [executions](./meta-5_monitor_past_and_future_runs-index.md) of this script are invisible to users other than the user running it, including the [owner(s)](./meta-16_roles_and_permissions-index.md). This setting can be overridden when this script is run manually from the advanced menu (available when the script is [deployed](./meta-0_draft_and_deploy-index.md)).

## Generated UI

main function's arguments can be given advanced settings that will affect the inputs' [auto-generated UI](./meta-6_auto_generated_uis-index.md) and [JSON Schema](./meta-13_json_schema_and_parsing-index.md).

Here is an example on how to define a [Python](./meta-2_python_quickstart-index.md) list as an enum of strings using the `Generated UI` menu.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="main-video"
	src="/videos/advanced_parameters_enum.mp4"
/>

<br/>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>

## Triggers

Triggers allow you to automate the execution of your scripts based on various events or conditions.

![Script triggers](../../static/images/script_triggers.png "Script triggers")

### Webhooks

Each Script and Flow created in Windmill gets autogenerated webhooks. The webhooks depend on how they are triggered, and what their return values are.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Webhooks"
		description="Each Script and Flow created in Windmill gets autogenerated webhooks."
		href="/docs/core_concepts/webhooks"
	/>
</div>

### Schedules

Schedules let you run your script at specified intervals or times, perfect for recurring tasks or periodic data updates.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Schedules"
		description="Scheduling allows you to define schedules for Scripts and Flows, automatically running them at set frequencies."
		href="/docs/core_concepts/scheduling"
	/>
</div>

### Routes

Windmill supports custom HTTP routes to trigger a script or flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Custom HTTP routes"
		description="Windmill supports custom HTTP routes to trigger a script or flow."
		href="/docs/core_concepts/http_routing"
	/>
</div>

### Websocket

Windmill can connect to WebSocket servers and trigger runnables (scripts, flows) when a message is received.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="WebSocket triggers"
		description="Trigger scripts and flows from WebSocket servers."
		href="/docs/core_concepts/websocket_triggers"
	/>
</div>

### Postgres

Windmill can connect to a [Postgres](https://www.postgresql.org/) database and trigger runnables (scripts, flows) in response to database transactions (INSERT, UPDATE, DELETE) on specified tables, schemas, or the entire database.  

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Postgres triggers"
		description="Trigger scripts and flows from postgres database servers."
		href="/docs/core_concepts/postgres_triggers"
	/>
</div>

### Kafka

Windmill can connect to Kafka brokers and trigger scripts or flows when messages are received on specific topics. This enables real-time processing of events from your Kafka ecosystem.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Kafka triggers"
		description="Trigger scripts and flows from Kafka messages."
		href="/docs/core_concepts/kafka_triggers"
	/>
</div>

### NATS

Windmill can connect to NATS brokers and trigger scripts or flows when messages are received on specific subjects. This enables real-time processing of events from your NATS ecosystem.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="NATS triggers"
		description="Trigger scripts and flows from NATS messages."
		href="/docs/core_concepts/nats_triggers"
	/>
</div>

### SQS triggers

Windmill can connect to Amazon SQS queues and trigger scripts or flows when messages are received. This enables event-driven processing from your AWS ecosystem. Preprocessors can transform the SQS message data before it reaches your script or flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="SQS triggers"
		description="Trigger scripts and flows from Amazon SQS messages."
		href="/docs/core_concepts/sqs_triggers"
	/>
</div>

### MQTT triggers

Windmill can connect to an MQTT broker, subscribe to specific topics, and trigger scripts or flows when messages are received, enabling event-driven processing. Preprocessors can transform the MQTT message data before it reaches your script or flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="MQTT triggers"
		description="Trigger scripts and flows from MQTT broker."
		href="/docs/core_concepts/mqtt_triggers"
	/>
</div>

### MQTT triggers

Windmill can connect to an MQTT broker, subscribe to specific topics, and trigger scripts or flows when messages are received, enabling event-driven processing. Preprocessors can transform the MQTT message data before it reaches your script or flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="MQTT triggers"
		description="Trigger scripts and flows from MQTT broker."
		href="/docs/core_concepts/mqtt_triggers"
	/>
</div>

### Email

Scripts and flows can be triggered by email messages sent to a specific email address, leveraging SMTP.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Email triggers"
		description="Scripts and flows can be triggered by email messages sent to a specific email address, leveraging SMTP."
		href="/docs/advanced/email_triggers"
	/>
</div>



## See Also

- [Script settings](../../static/images/script_languages.png 'Script settings')
- [Windmill AI](../core_concepts/22_ai_generation/index.mdx)
- [script's owner](../core_concepts/16_roles_and_permissions/index.mdx#permissions-and-access-control)
- [folder](../core_concepts/8_groups_and_folders/index.mdx#folders)
- [TypeScript](../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx)
