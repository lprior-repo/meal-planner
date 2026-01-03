---
id: tutorial/windmill/script-kinds
title: "Script kind"
category: tutorial
tags: ["windmill", "tutorial", "beginner", "script"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Script kind</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:28.172888</created_at>
  <updated_at>2026-01-02T19:55:28.172888</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Actions" level="2"/>
    <section name="Trigger scripts" level="2"/>
    <section name="Approval scripts" level="2"/>
    <section name="Error handlers" level="2"/>
    <section name="Preprocessors" level="2"/>
  </sections>
  <features>
    <feature>actions</feature>
    <feature>approval_scripts</feature>
    <feature>error_handlers</feature>
    <feature>preprocessors</feature>
    <feature>trigger_scripts</feature>
  </features>
  <dependencies>
    <dependency type="feature">tutorial/windmill/settings</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./settings.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,tutorial,beginner,script</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Script kind

> **Context**: import DocCard from '@site/src/components/DocCard';

You can attach additional functionalities to Scripts by specializing them into specific Script kinds.

From the [Settings](./tutorial-windmill-settings.md) of a script, the "Metadata" tab lets you define the following Script kinds:

## Actions

Actions are the basic building blocks for the flows.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Scripts quickstart"
		description="Start writing scripts in Python, TypeScript, Go, PHP, Bash and Sql."
		href="/docs/getting_started/scripts_quickstart"
	/>
	<DocCard
		title="Flows quickstart"
		description="Learn how to build flows."
		href="/docs/getting_started/flows_quickstart"
	/>
</div>

## Trigger scripts

These are used as the first step in flows, most commonly with an internal state and a schedule to watch for changes on a external system, and compare it to the previously saved state. If there are changes,it _triggers_ the rest of the flow, i.e. subsequent Scripts.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Trigger scripts"
		description="Trigger scripts are designed to pull data from an external source and return all of the new items since the last run, without resorting to external webhooks."
		href="/docs/flows/flow_trigger"
	/>
	<DocCard
		title="Schedules"
		description="Windmill provides the same set of features as CRON, but with a user interface and control panels."
		href="/docs/core_concepts/scheduling"
	/>
</div>

## Approval scripts

Suspend a flow until it's approved. An Approval Script will interact with the Windmill API using any of the Windmill clients to retrieve a secret approval URL and resume/cancel endpoints. Most common scenario for Approval scripts is to send an external notification with an URL that can be used to resume or cancel a flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Suspend & Approval / Prompts"
		description="Flows can be suspended until resumed or canceled event(s) are received."
		href="/docs/flows/flow_approval"
	/>
</div>

## Error handlers

Handle errors for Flows after all retries attempts have been exhausted. If it does not return an exception itself, the Flow is considered to be "recovered" and will have a success status. So in most cases, you will have to rethrow an error to have it be listed as a failed flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Error handler"
		description="The error handler is a special flow step that is executed when an error occurs in the flow."
		href="/docs/flows/flow_error_handler"
	/>
</div>

## Preprocessors

Preprocessors are used to preprocess the data before it is used in the flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Preprocessors"
		description="Preprocessors are used to preprocess the data before it is used in the flow."
		href="/docs/core_concepts/preprocessors"
	/>
</div>

## See Also

- [Settings](./settings.mdx)
