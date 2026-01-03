---
id: concept/windmill/10-flow-trigger
title: "Trigger scripts"
category: concept
tags: ["windmill", "trigger", "advanced", "concept"]
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

## Scheduled polls

:::tip

Think of this as someone who checks the mailbox every day. If there is a new
letter, they will continue to process it - open and read it - and if there is no
new letter, they won't do anything.

The key part is that opened letters are not placed back in the mailbox. In
Windmill, **a Trigger Script has the job to keep track of what's processed and
what's not**.

:::

Flows can be scheduled through the Flow UI using a CRON expression and then
activating the schedule as seen in the image below.

Example of a trigger script watching new Slack posts with a given word in a given channel and the flow sending each of them by email in a for loop:

![Example of a schedule script with a for loop](../getting_started/8_triggers/schedule-script.png 'Example of a schedule script with a for loop')

![Schedule](../getting_started/8_triggers/schedule-flow.png 'Schedule')

> This flow can be found on [WindmillHub](https://hub.windmill.dev/flows/51/watch-slack-posts-containing-a-given-word-and-send-all-new-ones-per-email).

<br />

Examples of trigger scripts include:

- [Trigger every time a new item text on HackerNews match at least one mention](https://hub.windmill.dev/scripts/hackernews/1301/trigger-everytime-a-new-item-text-on-hackernews-match-at-least-one-mention-hackernews)
- [Notify of new GitHub repo stars](https://hub.windmill.dev/scripts/github/1208/notify-of-new-github-repo-stars-github)
- [Check new uploaded files on Google Drive](https://hub.windmill.dev/scripts/gdrive/1457/get-new-files-gdrive)

The following TypeScript code is an example of the first module of a Flow that
checks for new documents in a MongoDB collection on a regular schedule. In this
case we query documents that were created after a specific time, expressed with
a timestamp. The timestamp is stored with the help of Windmill's built-in
[state functions](./meta-windmill-index-57.md#states) and is
updated in each run.

<details>
  <summary>Code below:</summary>

```ts
import { getState, type Resource, setState } from 'npm:windmill-client';
import { MongoClient, ObjectId } from 'https://deno.land/x/atlas_sdk/mod.ts';

type MongodbRest = {
	endpoint: string;
	api_key: string;
};

export async function main(
	auth: MongodbRest,
	data_source: string,
	database: string,
	collection: string
) {
	const client = new MongoClient({
		endpoint: auth.endpoint,
		dataSource: data_source,
		auth: { apiKey: auth.api_key }
	});
	const documents = client.database(database).collection(collection);
	const lastCheck = (await getState()) || 0;
	await setState(Date.now() / 1000);
	const id = ObjectId.createFromTime(lastCheck);
	return await documents.find({ _id: { $gt: id } });
}
```

</details>

:::tip

You can find this exact Trigger Script on
[Windmill Hub](https://hub.windmill.dev/scripts/mongodb/1462/get-recently-inserted-documents-mongodb),
or many more examples [here](https://hub.windmill.dev/triggers).

:::


## See Also

- [schedules](../core_concepts/1_scheduling/index.mdx)
- [states](../core_concepts/3_resources_and_types/index.mdx#states)
- [for loop](../flows/12_flow_loops.md)
- [Scheduling](../core_concepts/1_scheduling/index.mdx)
- [Triggering flows](../getting_started/8_triggers/index.mdx)
