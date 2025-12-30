---
id: tutorial/flows/15-sleep
title: "Sleeps / Delays in flows"
category: tutorial
tags: ["beginner", "flows", "sleeps", "tutorial"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Sleep/Delays</title>
  <description>Suspend flow execution for a specified duration</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Sleeps / Delays in flows" level="1"/>
    <section name="How to do it" level="2"/>
    <section name="Keep control of slept steps" level="2"/>
  </sections>
  <features>
    <feature>sleep</feature>
    <feature>delay</feature>
    <feature>passive_execution</feature>
  </features>
  <dependencies>
    <dependency type="feature">scheduling</dependency>
    <dependency type="feature">flow_approval</dependency>
  </dependencies>
  <examples count="4">
    <example>Customer relations welcome delay</example>
    <example>Support ticketing escalation delay</example>
    <example>Cybersecurity threat analysis delay</example>
    <example>Content moderation review delay</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,sleep,delay,pause,suspend,flow,passive</tags>
</doc_metadata>
-->

# Sleeps / Delays in flows

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Sleep/Delays</title> <description>Suspend flow execution for a specified 

Executions within a flow can be suspended for a given time.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    autoPlay
    loop
    controls
    id="main-video"
    src="/videos/sleep_step.mp4"
/>

<br/>

:::tip

This feature is made to hold a flow **inside of it**. Based on your specific needs, you may want to utilize other features:

- [Schedule the trigger](./meta-1_scheduling-index.md) of a script or flow.
- [Suspend a flow until a step is approved](./tutorial-flows-11-flow-approval.md).
- [Retry](./ops-flows-14-retries.md) a step multiple times until it is successful.
- [Early stop/Break](./concept-flows-2-early-stop.md) the flow if a step met a predicate expression.

:::

Each step of a flow can be paused after execution of a given amount of seconds. Although in seconds, this input can in fact handle several hours, days, months (years). Sleeping is passive and does not consume any resources.

From a single flow, this feature can for example help you with:

- **Customer relations**: after each user signs up, hold off for one day before dispatching a welcome email to prevent information overload.
- **Support ticketing**: when a user submits a ticket, introduce a 30-minute wait to give an opportunity for potential self-resolution prior to escalating to the support team.
- **Cybersecurity**: after an automated system identifies a possible threat, impose a 5-minute delay before alerting the security team, providing a window to filter out false positives.
- **Content moderation**: pause the release of user-submitted content for several hours, offering a chance for review and necessary adjustments.

And many more use cases.

## How to do it

Within a [flow](./meta-6_flows_quickstart-index.md), pick the step **after which** you want to suspend:

- go to `Advanced`
- click on `Sleep`
- set the duration of the pause
- toggle on

The bed icon will show the sleep step is activated.

![Sleep activation](../assets/flows/sleep_toggle.png.webp)

## Keep control of slept steps

The [Runs menu](./meta-5_monitor_past_and_future_runs-index.md) provides a dashboard to monitor all past, current and future runs. While a flow is executed and paused, you can see in a single view:

- the current state of the flow
- the steps that were already executed
- the incoming ones

![Sleep step from runs menu](../assets/flows/sleep_run_menu.png.webp)


## See Also

- [Schedule the trigger](../core_concepts/1_scheduling/index.mdx)
- [Suspend a flow until a step is approved](./11_flow_approval.mdx)
- [Retry](./14_retries.md)
- [Early stop/Break](./2_early_stop.md)
- [flow](../getting_started/6_flows_quickstart/index.mdx)
