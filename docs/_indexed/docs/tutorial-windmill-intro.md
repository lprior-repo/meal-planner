---
id: tutorial/windmill/intro
title: "What is Windmill?"
category: tutorial
tags: ["beginner", "windmill", "what", "tutorial"]
---

import DocCard from '@site/src/components/DocCard';
import VideoTour from '@site/src/components/VideoTour';
import { Book, Pen, Home, Cloud, Terminal, Play, Code, List, LayoutDashboard, Monitor } from 'lucide-react';

# What is Windmill?

> **Context**: import DocCard from '@site/src/components/DocCard'; import VideoTour from '@site/src/components/VideoTour'; import { Book, Pen, Home, Cloud, Terminal,

Windmill is a fast, **<a href="https://github.com/windmill-labs/windmill">open-source</a>** workflow engine and developer platform. It's an alternative to the likes of Retool, Superblocks, n8n, Airflow, Prefect, Kestra and Temporal, designed to **build comprehensive internal tools** (endpoints, workflows, UIs). It supports coding in TypeScript, Python, Go, PHP, Bash, C#, SQL and Rust, or any Docker image, alongside intuitive low-code builders, featuring:

- An [execution runtime](./meta-script_editor-index.md) for scalable, low-latency function execution across a worker fleet.
- An [orchestrator](./tutorial-flows-1-flow-editor.md) for assembling these functions into efficient, low-latency flows, using either a low-code builder or YAML.
- An [app builder](./apps/0_app_editor/index.mdx) for creating data-centric dashboards, utilizing low-code or JS frameworks like React.

Windmill supports both UI-based operations via its webIDE and low-code builders, as well as [CLI](./meta-3_cli-index.md) deployments [from a Git repository](./meta-11_git_sync-index.md), aligning with your preferred development style.

Start your project today with our **<a href="https://app.windmill.dev/" rel="nofollow" >Cloud App</a>** (no credit card needed) or opt for **<a href="/docs/advanced/self_host" >self-hosting</a>**.

<VideoTour />

## Develop faster

Focus on code that matters: your critical business logic, from data transformation to internal API calls, starts as scripts and SQL files. Windmill transforms these into scalable microservices and tools without the usual heavy lifting.

Boilerplate code is eliminated as Windmill takes care of the repetitive work of building UIs, [handling errors](./meta-10_error_handling-index.md), scaling logic, and [managing dependencies](./meta-6_imports-index.md), making these aspects more streamlined.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Getting started"
		description="Get started in 30 seconds."
		href="/docs/getting_started/how_to_use_windmill"
		Icon={Play}
	/>
	<DocCard
		title="Note of intent"
		description="The why and how of Windmill."
		href="/docs/misc/note_of_intent"
		Icon={Book}
	/>
</div>

## Core features

**An efficient runtime**: execute code [across languages](./meta-0_scripts_quickstart-index.md) with minimal overhead and instant starts.

**Smart dependency and input management**: automatically generate lockfiles and input specs from your code, ensuring consistent [dependency versions](./meta-6_imports-index.md) and simplified [input handling](./meta-13_json_schema_and_parsing-index.md).

**Dynamic web IDE and low-code builders**: create [scripts](./meta-script_editor-index.md) with advanced editing tools and [auto-generated UIs](./meta-6_auto_generated_uis-index.md), build [flows](./tutorial-flows-1-flow-editor.md) with a drag-and-drop interface, and design [apps](./apps/0_app_editor/index.mdx) without extensive coding.

**Enterprise-ready**: Windmill offers robust [permissioning](./meta-16_roles_and_permissions-index.md), [secret management](./meta-2_variables_and_secrets-index.md), OAuth, and more, wrapped in an enterprise-grade platform.

**Integrations and automations**: with [webhooks](./meta-4_webhooks-index.md), an [open API](https://app.windmill.dev/openapi.html), and a [scheduler](./meta-1_scheduling-index.md), Windmill fits seamlessly into your infrastructure, allowing for extensive automation capabilities.

**Local development**: develop scripts and flows locally using your favorite IDE with the [VS Code extension](./meta-1_vscode-extension-index.md) and [CLI](./meta-3_cli-index.md), then sync with [Git integration](./meta-11_git_sync-index.md) for version control and deployment workflows.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Core concepts"
		description="Learn about Windmill's core concepts in depth."
		href="/docs/getting_started/scripts_quickstart"
	/>
	<DocCard
		title="Enterprise onboarding"
		description="Essential setup information and best practices for new enterprise customers."
		href="/docs/misc/enterprise_onboarding"
	/>
</div>

## Compare

While other frameworks offer pieces of what Windmill does, none combine its comprehensive feature set with full open-source accessibility. Whether compared to workflow engines like Temporal and Airflow or UI builders like Retool, Windmill stands out for its scalability, open APIs, and ease of use.

Windmill is an open-source, self-hostable platform that marries the flexibility of code with the speed of low-code solutions, enabling seamless automation of repetitive tasks.

Learn how Windmill compares to other products like [Retool](./compared_to/retool.mdx), [n8n](./compared_to/peers.mdx#n8n), [Airflow](./misc/3_benchmarks/competitors/airflow/index.mdx), [Prefect](./compared_to/prefect.mdx), [Kestra](./compared_to/kestra.mdx) and [Temporal](./misc/3_benchmarks/competitors/temporal/index.mdx).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Benchmarks"
		description="Windmill has about the same performance as AWS Lambda for heavier workloads, but it is slower on cold starts for medium compute."
		href="/docs/misc/benchmarks"
	/>
	<DocCard
		title="Windmill compared to peers"
		description="See where Windmill sits in the market of workflow engines and compares to its peers."
		href="/docs/compared_to/peers"
	/>
</div>


## See Also

- [execution runtime](./script_editor/index.mdx)
- [orchestrator](./flows/1_flow_editor.mdx)
- [app builder](./apps/0_app_editor/index.mdx)
- [CLI](./advanced/3_cli/index.mdx)
- [from a Git repository](./advanced/11_git_sync/index.mdx)
