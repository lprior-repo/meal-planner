---
doc_id: tutorial/windmill/16-architecture
chunk_id: tutorial/windmill/16-architecture#chunk-1
heading_path: ["Architecture and data exchange"]
chunk_type: prose
tokens: 419
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Architecture and data exchange</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.954715</created_at>
  <updated_at>2026-01-02T19:55:27.954715</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Input transform" level="2"/>
    <section name="Connecting flow steps" level="3"/>
    <section name="Custom flow states" level="2"/>
    <section name="Shared directory" level="2"/>
  </sections>
  <features>
    <feature>connecting_flow_steps</feature>
    <feature>custom_flow_states</feature>
    <feature>input_transform</feature>
    <feature>js_main</feature>
    <feature>python_main</feature>
    <feature>shared_directory</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-100</dependency>
    <dependency type="feature">meta/windmill/index-96</dependency>
    <dependency type="feature">meta/windmill/index-30</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-89</dependency>
    <dependency type="feature">meta/windmill/index-91</dependency>
    <dependency type="feature">meta/windmill/index-18</dependency>
    <dependency type="feature">concept/windmill/10-flow-trigger</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../openflow/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/index.mdx</entity>
    <entity relationship="uses">../core_concepts/16_roles_and_permissions/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/5_sql_quickstart/index.mdx</entity>
    <entity relationship="uses">../advanced/7_docker/index.mdx</entity>
    <entity relationship="uses">./10_flow_trigger.mdx</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,tutorial,beginner,architecture</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Architecture and data exchange

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In Windmill, a workflow is a JSON serializable value in the [OpenFlow](./meta-windmill-index-100.md) format that consists of an input spec (similar to [Scripts](./meta-windmill-index-96.md)), and a linear sequence of steps, also referred to as modules. Each step consists of either:

1. Reference to a Script from the [Hub](https://hub.windmill.dev/).
2. Reference to a Script in your [workspace](./meta-windmill-index-30.md#workspace).
3. Inlined Script in [TypeScript](./meta-windmill-index-87.md) (Deno), [Python](./meta-windmill-index-88.md), [Go](./meta-windmill-index-89.md), [Bash](./meta-windmill-index-89.md), [SQL](./meta-windmill-index-91.md) or [non-supported languages](./meta-windmill-index-18.md).
4. [Trigger scripts](./concept-windmill-10-flow-trigger.md) which are a kind of Scripts that are meant to be first step of a scheduled Flow, that watch for external events and early exit the Flow if there is no new events.
5. [For loop](./tutorial-windmill-12-flow-loops.md) that iterates over elements and triggers the execution of an embedded flow for each element. The list is calculated dynamically as an [input transform](#input-transform).
6. [Branch](./concept-windmill-13-flow-branches.md#branch-one) to the first subflow that has a truthy predicate (evaluated in-order).
7. [Branches to all](./concept-windmill-13-flow-branches.md#branch-all) subflows and collect the results of each branch into an array.
8. [Approval/Suspend steps](./tutorial-windmill-11-flow-approval.md) which suspend the flow at no cost until it is resumed by getting an approval/resume signal.
9. Inner flows.

![Flow architecture](../assets/flows/flow_architecture.png.webp 'Flow architecture')
