---
id: ref/windmill/6-concurrency-limit
title: "Concurrency limits"
category: ref
tags: ["windmill", "reference", "concurrency"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>windmill</category>
  <title>Concurrency limits</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.993333</created_at>
  <updated_at>2026-01-02T19:55:27.993333</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Concurrency limit of flow" level="2"/>
    <section name="Concurrency limit of scripts within flow" level="2"/>
  </sections>
  <features>
    <feature>concurrency_limit_of_flow</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-36</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/pricing</entity>
    <entity relationship="uses">../core_concepts/21_concurrency_limits/index.md</entity>
    <entity relationship="uses">../core_concepts/21_concurrency_limits/index.md</entity>
    <entity relationship="uses">../core_concepts/21_concurrency_limits/index.md</entity>
    <entity relationship="uses">../assets/flows/concurrency_flow.png &apos;Concurrency limit of flow&apos;</entity>
    <entity relationship="uses">../assets/code_editor/concurrency_limit_flow.png &apos;Concurrency limit Scripts within Flow&apos;</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,reference,concurrency</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Concurrency limits

> **Context**: import DocCard from '@site/src/components/DocCard';

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:
- [Max number of executions within the time window](./meta-windmill-index-36.md#max-number-of-executions-within-the-time-window)
- [Time window in seconds](./meta-windmill-index-36.md#time-window-in-seconds)
- [Custom concurrency key](./meta-windmill-index-36.md#custom-concurrency-key)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Concurrency limits"
		description="The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows."
		href="/docs/core_concepts/concurrency_limits"
	/>
</div>

## Concurrency limit of flow

From the Flow Settings menu, pick "Concurrency" and define a time window and max number of executions of the flow within that time window.

![Concurrency limit of flow](../assets/flows/concurrency_flow.png 'Concurrency limit of flow')

## Concurrency limit of scripts within flow

The Concurrency limit operates globally and across flow runs. It involves two key parameters: "Maximum number of runs" and the "Per time window (seconds)."

Concurrency limit can be set for each step of a flow in the `Advanced` menu, on tab "Concurrency".

![Concurrency limit Scripts within Flow](../assets/code_editor/concurrency_limit_flow.png 'Concurrency limit Scripts within Flow')

## See Also

- [Cloud plans and Pro Enterprise Self-Hosted](/pricing)
- [Max number of executions within the time window](../core_concepts/21_concurrency_limits/index.md#max-number-of-executions-within-the-time-window)
- [Time window in seconds](../core_concepts/21_concurrency_limits/index.md#time-window-in-seconds)
- [Custom concurrency key](../core_concepts/21_concurrency_limits/index.md#custom-concurrency-key)
- [Concurrency limit of flow](../assets/flows/concurrency_flow.png 'Concurrency limit of flow')
