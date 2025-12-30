---
doc_id: tutorial/flows/16-architecture
chunk_id: tutorial/flows/16-architecture#chunk-1
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

In Windmill, a workflow is a JSON serializable value in the [OpenFlow](./meta-openflow-index.md) format that consists of an input spec (similar to [Scripts](./meta-0_scripts_quickstart-index.md)), and a linear sequence of steps, also referred to as modules. Each step consists of either:

1. Reference to a Script from the [Hub](https://hub.windmill.dev/).
2. Reference to a Script in your [workspace](./meta-16_roles_and_permissions-index.md#workspace).
3. Inlined Script in [TypeScript](./meta-1_typescript_quickstart-index.md) (Deno), [Python](./meta-2_python_quickstart-index.md), [Go](./meta-3_go_quickstart-index.md), [Bash](./meta-3_go_quickstart-index.md), [SQL](./meta-5_sql_quickstart-index.md) or [non-supported languages](./meta-7_docker-index.md).
4. [Trigger scripts](./concept-flows-10-flow-trigger.md) which are a kind of Scripts that are meant to be first step of a scheduled Flow, that watch for external events and early exit the Flow if there is no new events.
5. [For loop](./tutorial-flows-12-flow-loops.md) that iterates over elements and triggers the execution of an embedded flow for each element. The list is calculated dynamically as an [input transform](#input-transform).
6. [Branch](./concept-flows-13-flow-branches.md#branch-one) to the first subflow that has a truthy predicate (evaluated in-order).
7. [Branches to all](./concept-flows-13-flow-branches.md#branch-all) subflows and collect the results of each branch into an array.
8. [Approval/Suspend steps](./tutorial-flows-11-flow-approval.md) which suspend the flow at no cost until it is resumed by getting an approval/resume signal.
9. Inner flows.

![Flow architecture](../assets/flows/flow_architecture.png.webp 'Flow architecture')
