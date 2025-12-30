---
id: meta/21_concurrency_limits/index
title: "Concurrency limits"
category: meta
tags: ["meta", "concurrency", "21_concurrency_limits", "api"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Concurrency Limits</title>
  <description>Prevent exceeding API rate limits by controlling execution frequency</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Concurrency limits" level="1"/>
    <section name="Max number of executions within time window" level="2"/>
    <section name="Time window in seconds" level="2"/>
    <section name="Custom concurrency key" level="2"/>
  </sections>
  <features>
    <feature>concurrency_limits</feature>
    <feature>rate_limiting</feature>
    <feature>throttling</feature>
    <feature>api_protection</feature>
  </features>
  <dependencies>
    <dependency type="feature">enterprise_edition</dependency>
  </dependencies>
  <examples count="3">
    <example>API rate limit protection</example>
    <example>Database connection pool management</example>
    <example>External service throttling</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,concurrency,limit,rate-limit,API,throttle,queue</tags>
</doc_metadata>
-->

# Concurrency limits

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>core_concepts</category> <title>Concurrency Limits</title> <description>Prevent exceeding API rat

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:

## Max number of executions within the time window

The maximum number of executions allowed within the time window. If the number of executions exceeds this limit, the job is queued for execution at the next available optimal slot.

## Time window in seconds

Set in seconds, the time window defines the period within which the maximum number of executions is allowed.

## Custom concurrency key

This parameter is optional. Concurrency keys are global, you can have them be workspace specific using the variable `$workspace`. You can also use an argument's value using `$args[name_of_arg]`.

Jobs can be filtered from the [Runs menu](./meta-5_monitor_past_and_future_runs-index.md) using the Concurrency Key.

## Concurrency limit in Script & Flows

### Concurrency limit of a script

[Concurrency limit of a script](./ref-script_editor-concurrency-limit.md) can be set from the [Settings](./tutorial-script_editor-settings.md) menu. Pick "Runtime" and then "Concurrency limits" and define a time window, max number of executions of the script within that time window and optionally a custom concurrency key.

![Concurrency limit](../../assets/code_editor/concurrency_limit.png)

### Concurrency limit of a flow

From the Flow Settings Advanced menu, pick "Concurrency limits" and define a time window, a max number of executions of the flow within that time window and optionally a custom concurrency key.

![Concurrency limit of flow](../../assets/flows/concurrency_flow.png "Concurrency limit of flow")

### Concurrency limit of scripts within flow

The Concurrency limit operates globally and across flow runs. It involves two key parameters: "Maximum number of runs" and the "Per time window (seconds)."

Concurrency limit can be set for each step of a flow in the `Advanced` menu, on tab "Runtime" - "Concurrency".

![Concurrency limit Scripts within Flow](../../assets/code_editor/concurrency_limit_flow.png "Concurrency limit Scripts within Flow")

## See Also

- [Cloud plans and Pro Enterprise Self-Hosted](/pricing)
- [Runs menu](../5_monitor_past_and_future_runs/index.mdx)
- [Concurrency limit of a script](../../script_editor/concurrency_limit.mdx)
- [Settings](../../script_editor/settings.mdx)
- [Concurrency limit](../../assets/code_editor/concurrency_limit.png)
