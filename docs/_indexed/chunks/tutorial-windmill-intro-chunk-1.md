---
doc_id: tutorial/windmill/intro
chunk_id: tutorial/windmill/intro#chunk-1
heading_path: ["What is Windmill?"]
chunk_type: prose
tokens: 384
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>What is Windmill?</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import VideoTour from &apos;@site/src/components/VideoTour&apos;; import { Book, Pen, Home, Cloud, Terminal, Play, Code, List, LayoutDashboard, Monitor } from</description>
  <created_at>2026-01-02T19:55:28.152017</created_at>
  <updated_at>2026-01-02T19:55:28.152017</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Develop faster" level="2"/>
    <section name="Core features" level="2"/>
    <section name="Compare" level="2"/>
  </sections>
  <features>
    <feature>compare</feature>
    <feature>core_features</feature>
    <feature>develop_faster</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
    <dependency type="service">docker</dependency>
    <dependency type="feature">meta/windmill/index-101</dependency>
    <dependency type="feature">tutorial/windmill/1-flow-editor</dependency>
    <dependency type="feature">meta/windmill/index-14</dependency>
    <dependency type="feature">meta/windmill/index-2</dependency>
    <dependency type="feature">meta/windmill/index-24</dependency>
    <dependency type="feature">meta/windmill/index-17</dependency>
    <dependency type="feature">meta/windmill/index-96</dependency>
    <dependency type="feature">meta/windmill/index-27</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./script_editor/index.mdx</entity>
    <entity relationship="uses">./flows/1_flow_editor.mdx</entity>
    <entity relationship="uses">./apps/0_app_editor/index.mdx</entity>
    <entity relationship="uses">./advanced/3_cli/index.mdx</entity>
    <entity relationship="uses">./advanced/11_git_sync/index.mdx</entity>
    <entity relationship="uses">./core_concepts/10_error_handling/index.mdx</entity>
    <entity relationship="uses">./advanced/6_imports/index.mdx</entity>
    <entity relationship="uses">./getting_started/0_scripts_quickstart/index.mdx</entity>
    <entity relationship="uses">./advanced/6_imports/index.mdx</entity>
    <entity relationship="uses">./core_concepts/13_json_schema_and_parsing/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,what</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import VideoTour from '@site/src/components/VideoTour';
import { Book, Pen, Home, Cloud, Terminal, Play, Code, List, LayoutDashboard, Monitor } from 'lucide-react';

# What is Windmill?

> **Context**: import DocCard from '@site/src/components/DocCard'; import VideoTour from '@site/src/components/VideoTour'; import { Book, Pen, Home, Cloud, Terminal,

Windmill is a fast, **<a href="https://github.com/windmill-labs/windmill">open-source</a>** workflow engine and developer platform. It's an alternative to the likes of Retool, Superblocks, n8n, Airflow, Prefect, Kestra and Temporal, designed to **build comprehensive internal tools** (endpoints, workflows, UIs). It supports coding in TypeScript, Python, Go, PHP, Bash, C#, SQL and Rust, or any Docker image, alongside intuitive low-code builders, featuring:

- An [execution runtime](./meta-windmill-index-101.md) for scalable, low-latency function execution across a worker fleet.
- An [orchestrator](./tutorial-windmill-1-flow-editor.md) for assembling these functions into efficient, low-latency flows, using either a low-code builder or YAML.
- An [app builder](./apps/0_app_editor/index.mdx) for creating data-centric dashboards, utilizing low-code or JS frameworks like React.

Windmill supports both UI-based operations via its webIDE and low-code builders, as well as [CLI](./meta-windmill-index-14.md) deployments [from a Git repository](./meta-windmill-index-2.md), aligning with your preferred development style.

Start your project today with our **<a href="https://app.windmill.dev/" rel="nofollow" >Cloud App</a>** (no credit card needed) or opt for **<a href="/docs/advanced/self_host" >self-hosting</a>**.

<VideoTour />
