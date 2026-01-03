---
doc_id: tutorial/windmill/4-cache
chunk_id: tutorial/windmill/4-cache#chunk-1
heading_path: ["Caching"]
chunk_type: prose
tokens: 254
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Caching</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.988951</created_at>
  <updated_at>2026-01-02T19:55:27.988951</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Cache flows" level="2"/>
    <section name="Cache flow steps" level="2"/>
    <section name="Conclusion" level="2"/>
  </sections>
  <features>
    <feature>cache_flow_steps</feature>
    <feature>cache_flows</feature>
    <feature>conclusion</feature>
  </features>
  <dependencies>
    <dependency type="feature">concept/windmill/5-step-mocking</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../assets/flows/cache_steps.gif</entity>
    <entity relationship="uses">./5_step_mocking.md</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,caching,beginner</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Caching

> **Context**: import DocCard from '@site/src/components/DocCard';

Caching is used to cache the results of a script, flow, flow step or app inline scripts for a specified number of seconds, thereby reducing the need for redundant computations when re-running the same step with identical input.

When you configure caching, Windmill stores the result in a cache for the duration you specify. If the same runnable is re-triggered with the same input within this duration, Windmill instantly retrieves the cached result instead of re-computing it.

This feature can significantly improve the performance of your scripts & flows, especially for steps that are computationally demanding or dependent on external resources, such as APIs or databases.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Caching"
		description="Caching is used to cache the results of a script, flow or flow step for a specified number of seconds."
		href="/docs/core_concepts/caching"
	/>
</div>
