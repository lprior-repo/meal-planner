---
doc_id: meta/6_flows_quickstart/index
chunk_id: meta/6_flows_quickstart/index#chunk-1
heading_path: ["Flows quickstart"]
chunk_type: prose
tokens: 345
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Flows quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

The present document will introduce you to [Flows](./tutorial-flows-1-flow-editor.md) and how to build your first one.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/yE-eDNWTj3g"
	title="Flows quickstart"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

> [Here](https://hub.windmill.dev/flows/43/) is an example of a simple flow built with Windmill.

<br />

Have in mind that in Windmill, Scripts are at the basis of Flows and Apps. To sum up roughly, workflows are state machines [represented as DAGs](./tutorial-flows-16-architecture.md) (Directed Acyclic Graphs) to compose scripts together. To learn more about scripts, check the [Script quickstart](./meta-0_scripts_quickstart-index.md). You will not necessarily have to re-build each script as you can reuse them from your workspace or from the [Hub](https://hub.windmill.dev/).

Those workflows can run for-loops, branches (parralellizable) suspend themselves until a timeout or receiving events such as webhooks or approvals. They can be scheduled very frequently and check for new external items to process (what we call "Trigger" script).

The result of a flow is the result of the last step executed, unless [error](./concept-flows-8-error-handling.md) was returned before or [Early return](./ops-flows-19-early-return.md) is set.

The overhead and coldstart between each step is about 20ms, which is [faster than any other orchestration engine](/blog/launch-week-1/fastest-workflow-engine), by a large margin.

To create your first workflow, you could also pick one from our [Hub](https://hub.windmill.dev/flows) and fork it. Here, we're going to build our own flow from scratch, step by step.

From [Windmill](./meta-00_how_to_use_windmill-index.md), click on `+ Flow`, and let's get started!

:::tip

Follow our [detailed section](./tutorial-flows-1-flow-editor.md) on the Flow editor for more information.

:::
