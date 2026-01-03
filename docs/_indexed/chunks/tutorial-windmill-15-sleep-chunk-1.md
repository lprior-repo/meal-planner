---
doc_id: tutorial/windmill/15-sleep
chunk_id: tutorial/windmill/15-sleep#chunk-1
heading_path: ["Sleeps / Delays in flows"]
chunk_type: prose
tokens: 540
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Sleeps / Delays in flows</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;Sleep/Delays&lt;/title&gt; &lt;description&gt;Suspend flow execution for a specified duration&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:0</description>
  <created_at>2026-01-02T19:55:27.952422</created_at>
  <updated_at>2026-01-02T19:55:27.952422</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="How to do it" level="2"/>
    <section name="Keep control of slept steps" level="2"/>
  </sections>
  <features>
    <feature>how_to_do_it</feature>
    <feature>keep_control_of_slept_steps</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-34</dependency>
    <dependency type="feature">tutorial/windmill/11-flow-approval</dependency>
    <dependency type="feature">ops/windmill/14-retries</dependency>
    <dependency type="feature">concept/windmill/2-early-stop</dependency>
    <dependency type="feature">meta/windmill/index-97</dependency>
    <dependency type="feature">meta/windmill/index-76</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/1_scheduling/index.mdx</entity>
    <entity relationship="uses">./11_flow_approval.mdx</entity>
    <entity relationship="uses">./14_retries.md</entity>
    <entity relationship="uses">./2_early_stop.md</entity>
    <entity relationship="uses">../getting_started/6_flows_quickstart/index.mdx</entity>
    <entity relationship="uses">../assets/flows/sleep_toggle.png.webp</entity>
    <entity relationship="uses">../core_concepts/5_monitor_past_and_future_runs/index.mdx</entity>
    <entity relationship="uses">../assets/flows/sleep_run_menu.png.webp</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,tutorial,beginner,sleeps</tags>
</doc_metadata>
-->

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

- [Schedule the trigger](./meta-windmill-index-34.md) of a script or flow.
- [Suspend a flow until a step is approved](./tutorial-windmill-11-flow-approval.md).
- [Retry](./ops-windmill-14-retries.md) a step multiple times until it is successful.
- [Early stop/Break](./concept-windmill-2-early-stop.md) the flow if a step met a predicate expression.

:::

Each step of a flow can be paused after execution of a given amount of seconds. Although in seconds, this input can in fact handle several hours, days, months (years). Sleeping is passive and does not consume any resources.

From a single flow, this feature can for example help you with:

- **Customer relations**: after each user signs up, hold off for one day before dispatching a welcome email to prevent information overload.
- **Support ticketing**: when a user submits a ticket, introduce a 30-minute wait to give an opportunity for potential self-resolution prior to escalating to the support team.
- **Cybersecurity**: after an automated system identifies a possible threat, impose a 5-minute delay before alerting the security team, providing a window to filter out false positives.
- **Content moderation**: pause the release of user-submitted content for several hours, offering a chance for review and necessary adjustments.

And many more use cases.
