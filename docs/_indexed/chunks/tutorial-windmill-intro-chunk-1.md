---
doc_id: tutorial/windmill/intro
chunk_id: tutorial/windmill/intro#chunk-1
heading_path: ["What is Windmill?"]
chunk_type: prose
tokens: 254
summary: "import DocCard from '@site/src/components/DocCard';"
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
