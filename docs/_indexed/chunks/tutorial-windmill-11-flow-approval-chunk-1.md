---
doc_id: tutorial/windmill/11-flow-approval
chunk_id: tutorial/windmill/11-flow-approval#chunk-1
heading_path: ["Suspend & Approval / Prompts"]
chunk_type: prose
tokens: 604
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Suspend &amp; Approval / Prompts</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.932096</created_at>
  <updated_at>2026-01-02T19:55:27.932096</updated_at>
  <language>en</language>
  <sections count="21">
    <section name="Add approval script" level="2"/>
    <section name="Core" level="2"/>
    <section name="Number of approvals/events required for resuming flow" level="3"/>
    <section name="Timeout" level="3"/>
    <section name="Continue on disapproval/timeout" level="3"/>
    <section name="Form" level="2"/>
    <section name="Use arguments" level="3"/>
    <section name="Prompts" level="3"/>
    <section name="Default args" level="3"/>
    <section name="Dynamics enums" level="3"/>
  </sections>
  <features>
    <feature>add_approval_script</feature>
    <feature>automated_trigger_version</feature>
    <feature>continue_on_disapprovaltimeout</feature>
    <feature>core</feature>
    <feature>default_args</feature>
    <feature>description</feature>
    <feature>disable_self-approval</feature>
    <feature>dynamics_enums</feature>
    <feature>form</feature>
    <feature>get_the_users_who_approved_the_flow</feature>
    <feature>hide_cancel_button_on_approval_page</feature>
    <feature>js_card_block</feature>
    <feature>js_customers</feature>
    <feature>js_main</feature>
    <feature>js_resumeUrls</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="library">requests</dependency>
    <dependency type="feature">concept/windmill/2-early-stop</dependency>
    <dependency type="feature">tutorial/windmill/15-sleep</dependency>
    <dependency type="feature">ops/windmill/14-retries</dependency>
    <dependency type="feature">meta/windmill/index-34</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">ops/windmill/ts-client</dependency>
    <dependency type="feature">concept/windmill/13-flow-branches</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../assets/flows/approval_diagram.png &apos;Approval step diagram&apos;</entity>
    <entity relationship="uses">./2_early_stop.md</entity>
    <entity relationship="uses">./15_sleep.md</entity>
    <entity relationship="uses">./14_retries.md</entity>
    <entity relationship="uses">../core_concepts/1_scheduling/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../assets/flows/approval-step.png &apos;Adding approval step&apos;</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../advanced/2_clients/ts_client.mdx</entity>
  </related_entities>
  <examples count="16">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>15</estimated_reading_time>
  <tags>windmill,tutorial,suspend,beginner</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Suspend & Approval / Prompts

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Flows can be suspended until resumed or canceled event(s) are received. This
feature is most useful for implementing approval steps.

![Approval step diagram](../assets/flows/approval_diagram.png 'Approval step diagram')

An approval step is a normal script with the **Suspend** option enabled in the step's advanced settings. This will suspend the execution of a flow until it has been approved through the resume endpoints or the approval page by and solely by the recipients of the secret URLs.

:::info Suspending a flow in Windmill

Other ways to pause a workflow include:

- [Early stop/Break](./concept-windmill-2-early-stop.md): if defined, at the end of the step, the predicate expression will be evaluated to decide if the flow should stop early.
- [Sleep](./tutorial-windmill-15-sleep.md): if defined, at the end of the step, the flow will sleep for a number of seconds before scheduling the next job (if any, no effect if the step is the last one).
- [Retry](./ops-windmill-14-retries.md) a step a step until it comes successful.
- [Schedule the trigger](./meta-windmill-index-34.md) of a script or flow.

:::

An event can be:

- a cancel
- a pre-set number of approval that is met.

The approval step generates a unique URL for each required approval using `wmill.getResumeUrls()` (or `wmill.get_resume_urls()` in [Python](./meta-windmill-index-88.md)). The approval step works like a webhook mechanism - the flow remains suspended until the required number of approval events are received via HTTP requests to these generated URLs. Each approval event is an HTTP request to one of these URLs, which then resumes or cancels the flow execution.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="WindmillHub | Approval"
		description="Find a library of Approval scripts on WindmillHub."
		href="https://hub.windmill.dev/approvals"
		color="teal"
	/>
</div>

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/flow-approval.mp4"
/>

<br />
