---
doc_id: tutorial/windmill/16-architecture
chunk_id: tutorial/windmill/16-architecture#chunk-1
heading_path: ["Architecture and data exchange"]
chunk_type: prose
tokens: 279
summary: "import DocCard from '@site/src/components/DocCard';"
---

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
