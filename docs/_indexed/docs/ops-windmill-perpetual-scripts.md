---
id: ops/windmill/perpetual-scripts
title: "Running services with perpetual scripts"
category: ops
tags: ["windmill", "running", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Running services with perpetual scripts</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:28.171606</created_at>
  <updated_at>2026-01-02T19:55:28.171606</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="How to enable perpetual scripts" level="2"/>
    <section name="How to disable perpetual scripts" level="2"/>
    <section name="Tutorial" level="2"/>
  </sections>
  <features>
    <feature>how_to_disable_perpetual_scripts</feature>
    <feature>how_to_enable_perpetual_scripts</feature>
    <feature>tutorial</feature>
  </features>
  <dependencies>
    <dependency type="feature">tutorial/windmill/settings</dependency>
    <dependency type="feature">meta/windmill/index-23</dependency>
    <dependency type="feature">meta/windmill/index-35</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./settings.mdx</entity>
    <entity relationship="uses">../core_concepts/0_draft_and_deploy/index.mdx</entity>
    <entity relationship="uses">../core_concepts/20_jobs/index.mdx</entity>
    <entity relationship="uses">../assets/script_editor/cancel.png &apos;Cancel perpetual script&apos;</entity>
    <entity relationship="uses">../assets/script_editor/scale_down_to_zero.png &apos;Scale down to zero&apos;</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,running,operations</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Running services with perpetual scripts

> **Context**: import DocCard from '@site/src/components/DocCard';

Perpetual scripts restart upon ending unless canceled.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/5uw3JWiIFp0"
	title="Perpetual Scripts"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

## How to enable perpetual scripts

In the script's [Settings](./tutorial-windmill-settings.md), go to the Runtime tab and enable "Perpetual Script", then [Deploy](./meta-windmill-index-23.md) the script.

## How to disable perpetual scripts

Canceling one [job](./meta-windmill-index-35.md) from a perpetual script is enough to disable it. You can do it from "Cancel" button.

![Cancel perpetual script](../assets/script_editor/cancel.png 'Cancel perpetual script')

You can also click on "Scale down to zero" in the "Current runs" tab.

![Scale down to zero](../assets/script_editor/scale_down_to_zero.png 'Scale down to zero')

## Tutorial

To learn more about Perpetual Scripts, you can visit our tutorial on how to use a perpetual script to implement a service in Windmill leveraging [Apache Kafka](https://kafka.apache.org/):

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Service script pattern in Windmill using Kafka"
		description="This example shows how to use a perpetual script to implement a service in Windmill leveraging Kafka."
		href="/blog/service-script-kafka"
	/>
</div>


## See Also

- [Settings](./settings.mdx)
- [Deploy](../core_concepts/0_draft_and_deploy/index.mdx)
- [job](../core_concepts/20_jobs/index.mdx)
- [Cancel perpetual script](../assets/script_editor/cancel.png 'Cancel perpetual script')
- [Scale down to zero](../assets/script_editor/scale_down_to_zero.png 'Scale down to zero')
