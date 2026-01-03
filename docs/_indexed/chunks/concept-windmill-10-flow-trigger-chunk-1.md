---
doc_id: concept/windmill/10-flow-trigger
chunk_id: concept/windmill/10-flow-trigger#chunk-1
heading_path: ["Trigger scripts"]
chunk_type: prose
tokens: 347
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Trigger scripts</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.928519</created_at>
  <updated_at>2026-01-02T19:55:27.928519</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Scheduled polls" level="2"/>
  </sections>
  <features>
    <feature>js_client</feature>
    <feature>js_documents</feature>
    <feature>js_id</feature>
    <feature>js_lastCheck</feature>
    <feature>js_main</feature>
    <feature>scheduled_polls</feature>
  </features>
  <dependencies>
    <dependency type="service">mongodb</dependency>
    <dependency type="feature">meta/windmill/index-34</dependency>
    <dependency type="feature">meta/windmill/index-57</dependency>
    <dependency type="feature">tutorial/windmill/12-flow-loops</dependency>
    <dependency type="feature">meta/windmill/index-99</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/1_scheduling/index.mdx</entity>
    <entity relationship="uses">../core_concepts/3_resources_and_types/index.mdx</entity>
    <entity relationship="uses">../flows/12_flow_loops.md</entity>
    <entity relationship="uses">../core_concepts/1_scheduling/index.mdx</entity>
    <entity relationship="uses">../getting_started/8_triggers/index.mdx</entity>
    <entity relationship="uses">../getting_started/8_triggers/schedule-script.png &apos;Example of a schedule script with a for loop&apos;</entity>
    <entity relationship="uses">../getting_started/8_triggers/schedule-flow.png &apos;Schedule&apos;</entity>
    <entity relationship="uses">../core_concepts/3_resources_and_types/index.mdx</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,trigger,advanced,concept</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Trigger scripts

> **Context**: import DocCard from '@site/src/components/DocCard';

Trigger scripts are designed to pull data from an external source and return all of the new items since the last run, without resorting to external webhooks. A trigger script is intended to be used as scheduled poll with [schedules](./meta-windmill-index-34.md) and [states](./meta-windmill-index-57.md#states) (rich objects in JSON, persistent from one run to another) in order to compare the execution to the previous one and process each new item in a [for loop](./tutorial-windmill-12-flow-loops.md). If there are no new items, the flow will be skipped.

By default, adding a trigger will set the schedule to 15 minutes.

:::info

Check our pages dedicated to [Scheduling](./meta-windmill-index-34.md) and [Triggering flows](./meta-windmill-index-99.md).

:::

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="States"
		description="A state is an object stored as a resource of the resource type `state` which is meant to persist across distinct executions of the same script."
		href="/docs/core_concepts/resources_and_types#states"
		color="teal"
	/>
	<DocCard
		title="Schedules"
		description="Scheduling allows you to define schedules for Scripts and Flows, automatically running them at set frequencies."
		href="/docs/core_concepts/scheduling"
		color="teal"
	/>
	<DocCard
		color="teal"
		title="For loops"
		description="Iterate a series of tasks."
		href="/docs/flows/flow_loops"
	/>
</div>
