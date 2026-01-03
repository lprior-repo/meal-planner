---
id: concept/windmill/8-error-handling
title: "Error handling in flows"
category: concept
tags: ["windmill", "concept", "error"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Error handling in flows</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.996687</created_at>
  <updated_at>2026-01-02T19:55:27.996687</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Error handler" level="2"/>
    <section name="Retries" level="2"/>
    <section name="Early stop / Break" level="2"/>
    <section name="Custom timeout for step" level="2"/>
    <section name="Error handling" level="2"/>
  </sections>
  <features>
    <feature>custom_timeout_for_step</feature>
    <feature>early_stop_break</feature>
    <feature>error_handler</feature>
    <feature>error_handling</feature>
    <feature>retries</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/windmill/14-retries</dependency>
    <dependency type="feature">tutorial/windmill/7-flow-error-handler</dependency>
    <dependency type="feature">concept/windmill/2-early-stop</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./14_retries.md</entity>
    <entity relationship="uses">./7_flow_error_handler.md</entity>
    <entity relationship="uses">./2_early_stop.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,concept,error</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Error handling in flows

> **Context**: import DocCard from '@site/src/components/DocCard';

There are four ways to handle errors in Windmill flows: [retries](./ops-windmill-14-retries.md), [error handlers](./tutorial-windmill-7-flow-error-handler.md), and [early stop/break](./concept-windmill-2-early-stop.md).

## Error handler

The Error handler is a special flow step that is executed when an error occurs within a flow.

If defined, the error handler will take as input the result of the step that errored (which has its error in the 'error field').

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/error_handler.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Error handler"
		description="Configure a script to handle errors."
		href="/docs/flows/flow_error_handler"
	/>
</div>

## Retries

Steps within a flow can be retried a specified number of times and at a defined frequency in case of an error.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/retries_example.mp4"
/>

<br />

> Example of a flow step giving error if random number = 0 and re-trying 5 times

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Retries"
		description="Re-try a step in case of error."
		href="/docs/flows/retries"
	/>
</div>

## Early stop / Break

The Early stop/Break feature allows you to define a predicate expression that determines whether the flow should stop early at the end or before a step.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/early_stop.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Early stop / Break"
		description="Stop early a flow based on a step's result."
		href="/docs/flows/early_stop"
	/>
</div>

## Custom timeout for step

For each step can be defined a timeout. If the execution takes longer than the time limit, the execution of the step will be interrupted.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/custom_timeout.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Custom timeout for step"
		description="For each step can be defined a timeout. If the execution takes longer than the time limit, the execution of the step will be interrupted."
		href="/docs/flows/custom_timeout"
	/>
</div>

## Error handling

For more details on Error handling, see:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Error handling"
		description="There are 5 ways to do error handling in Windmill."
		href="/docs/core_concepts/error_handling"
	/>
</div>


## See Also

- [retries](./14_retries.md)
- [error handlers](./7_flow_error_handler.md)
- [early stop/break](./2_early_stop.md)
