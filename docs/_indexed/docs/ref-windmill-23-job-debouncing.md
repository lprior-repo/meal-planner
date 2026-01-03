---
id: ref/windmill/23-job-debouncing
title: "Job debouncing"
category: ref
tags: ["windmill", "job", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>windmill</category>
  <title>Job debouncing</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.972711</created_at>
  <updated_at>2026-01-02T19:55:27.972711</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Job debouncing of flow" level="2"/>
  </sections>
  <features>
    <feature>job_debouncing_of_flow</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-38</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/pricing</entity>
    <entity relationship="uses">../core_concepts/22_job_debouncing/index.md</entity>
    <entity relationship="uses">../core_concepts/22_job_debouncing/index.md</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,job,reference</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Job debouncing

> **Context**: import DocCard from '@site/src/components/DocCard';

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window. This feature helps optimize resource usage and prevents unnecessary duplicate computations.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Debouncing can be set from the Settings menu. When jobs with matching characteristics are submitted within the debounce window, pending jobs are automatically canceled in favor of the newest one.

The Job debouncing operates globally and across flow runs. It involves two key parameters:
- [Debounce delay in seconds](./meta-windmill-index-38.md#debounce-delay-in-seconds)
- [Custom debounce key](./meta-windmill-index-38.md#custom-debounce-key)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Job debouncing"
		description="Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics."
		href="/docs/core_concepts/job_debouncing"
	/>
</div>

## Job debouncing of flow

From the Flow Settings menu, pick "Debouncing" and define a time window and optionally a custom debounce key.

## See Also

- [Cloud plans and Pro Enterprise Self-Hosted](/pricing)
- [Debounce delay in seconds](../core_concepts/22_job_debouncing/index.md#debounce-delay-in-seconds)
- [Custom debounce key](../core_concepts/22_job_debouncing/index.md#custom-debounce-key)
