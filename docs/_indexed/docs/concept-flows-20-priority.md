---
id: concept/flows/20-priority
title: "Priority for steps"
category: concept
tags: ["concept", "priority", "flows"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Priority</title>
  <description>Prioritize flow steps in execution queue</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Priority for steps" level="1"/>
  </sections>
  <features>
    <feature>priority</feature>
    <feature>queue_management</feature>
    <feature>high_priority_jobs</feature>
  </features>
  <dependencies>
    <dependency type="feature">execution_queue</dependency>
  </dependencies>
  <examples count="1">
    <example>High priority critical jobs</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,priority,queue,execution,enterprise,high-priority</tags>
</doc_metadata>
-->

# Priority for steps

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Priority</title> <description>Prioritize flow steps in execution queue</d

Prioritize a flow step in the execution queue.

![Set flow priority](../assets/flows/flow_priority.png "Set flow priority")

By enabling "Priority", jobs scheduled from this step when the flow is executed are labeled as high priority and take precedence over the other jobs in the jobs queue.

Priority can be assigned from 1 to 100, with 100 being the highest priority. All jobs for which this option is not enabled are assigned priority 0.

This feature is exclusive to [Self-Hosted Enterprise](/pricing).

## See Also

- [Set flow priority](../assets/flows/flow_priority.png "Set flow priority")
- [Self-Hosted Enterprise](/pricing)
