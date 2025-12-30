---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-1
heading_path: ["Schedules"]
chunk_type: prose
tokens: 557
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Schedules

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill provides the same set of features as CRON, but with a user interface and control panels. It allows you to define Schedules for Scripts and Flows. Once a schedule is defined, the script will automatically run at the set frequency. Think of it as an easy-to-use scheduler similar to CRON that you can share with other users.

A Schedule consists of a Script or Flow, its arguments, a CRON expression that controls the execution frequency and optional Error and Recovery Handlers to deal with failed scheduled executions.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/schedule-cron-menu.mp4"
/>

<br />

Cron is a powerful and versatile tool that enables users to automate tasks by scheduling them to run at specific intervals or times. From automating routine system maintenance to sending periodic email reports, cron plays an indispensable role in streamlining processes and improving productivity for developers, system administrators, and even casual users.

However, as with any powerful tool, using outside Windmill cron comes with its own set of challenges and potential issues. Common problems associated with the use of cron include:

- **Runs History**: to maintain a record of script runs and log outputs through cron, you must manually incorporate that logic.
- **Error handling**: in the event of a failed run, self-crafted logic is required for notifications (Slack, emails).
- **Manual Runs**: executing a cron job manually, outside of its schedule, proves difficult and can lead to inconsistencies due to potential environment differences.
- **No UI**: navigating cron jobs is challenging without a centralized hub, particularly for larger engineering teams. This comes with induced issues: 1. **Handling permissions and Errors** among users and editors and 2. **Server downtime**: when the server hosting the job experiences downtime, monitoring and alerting is problematic.

Windmill addresses these issues with schedules that can be defined with pre-set configuration for scripts and flows.

:::info A bit of Context: How Windmill Works

[Windmill](./tutorial-windmill-intro.md) is an open-source developer platform and infra to build all internal tools through code, such as UIs and workflows based on simple scripts (TypeScript, Python, Go, PHP, Bash, C#, SQL and Rust).

<br />

Managing scripts, flows and apps on Windmill works at the [workspace](./meta-16_roles_and_permissions-index.md#workspace)-level. Admins invite developers and operators to the workspace where are hosted workflows. The first two can write and edit flows as well as managing permissions, executions etc.

<br />

Cron jobs are one of many ways to [trigger workflows](./meta-8_triggers-index.md) in Windmill (among [webhooks](./meta-4_webhooks-index.md), [auto-generated UIs](./meta-6_auto_generated_uis-index.md), [customized UIs][apps], [Command-line interface](./meta-3_cli-index.md), [Slackbots](/blog/handler-slack-commands) etc.)

:::
