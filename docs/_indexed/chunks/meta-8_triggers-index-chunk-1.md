---
doc_id: meta/8_triggers/index
chunk_id: meta/8_triggers/index#chunk-1
heading_path: ["Triggers"]
chunk_type: prose
tokens: 178
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Triggers

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill scripts and flows can be triggered in various ways.

On-demand triggers:

- [Auto-generated UIs](./meta-8_triggers-index.md#auto-generated-uis)
- [Customized UIs with the App editor](#customized-uis-with-the-app-editor)
- [Trigger from flows](#trigger-from-flows)
- [Workflows as code](#workflows-as-code) (scripts only)
- [Schedule](#schedule)
- [Command-line interface (CLI)](#cli-command-line-interface)
- [Trigger from API](#trigger-from-api)
- [Trigger from LLM clients with MCP](#trigger-from-llm-clients-with-mcp)

Triggers from external events:

- [Webhooks](#webhooks), including from [Slack](#webhooks-trigger-scripts-from-slack)
- [Emails](#emails)
- [Custom HTTP routes](#custom-http-routes)
- [WebSocket triggers](#websocket-triggers)
- [Postgres triggers](#postgres-triggers)
- [Kafka triggers](#kafka-triggers)
- [NATS triggers](#nats-triggers)
- [SQS triggers](#sqs-triggers)
- [MQTT triggers](#mqtt-triggers)
- [GCP triggers](#gcp-triggers)
- [Scheduled polls](#scheduled-polls-scheduling--trigger-scripts)

:::info Scripts and Flows in Windmill
[Scripts](./meta-1_typescript_quickstart-index.md) are sequences of instructions that automate tasks or perform specific operations. [Flows](./tutorial-flows-1-flow-editor.md) are sequences of scripts that execute one after another or in parallel. Both are hosted in workspaces.
:::
