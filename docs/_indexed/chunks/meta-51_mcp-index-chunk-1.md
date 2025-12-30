---
doc_id: meta/51_mcp/index
chunk_id: meta/51_mcp/index#chunk-1
heading_path: ["Windmill MCP"]
chunk_type: prose
tokens: 235
summary: "Windmill MCP"
---

# Windmill MCP

> **Context**: Windmill supports the [**Model Context Protocol (MCP)**](https://modelcontextprotocol.io/introduction), an open standard that enables seamless interac

Windmill supports the [**Model Context Protocol (MCP)**](https://modelcontextprotocol.io/introduction), an open standard that enables seamless interaction between LLMs and tools like Windmill.

With MCP, you can connect your favorite LLMs (like [Claude](https://claude.ai/download), [Cursor](https://www.cursor.com), or any [MCP compatible client](https://modelcontextprotocol.io/clients)) to Windmill, allowing you to trigger your scripts and flows from your client chat.

Additionally, MCP provides access to Windmill's API endpoints for basic operations on:
- **[Jobs](./meta-20_jobs-index.md)** - Monitor and manage [job](./meta-20_jobs-index.md) executions, including tracking their progress, retrieving logs, and viewing execution results
- **[Resources](./meta-3_resources_and_types-index.md)** - Create, read, update, and delete [resources](./meta-3_resources_and_types-index.md) for third-party system connections like databases and APIs
- **[Variables](./meta-2_variables_and_secrets-index.md)** - Manage workspace [variables and secrets](./meta-2_variables_and_secrets-index.md) for secure credential storage and configuration management  
- **[Schedules](./meta-1_scheduling-index.md)** - Control [scheduled executions](./meta-1_scheduling-index.md) with CRON-like automation for scripts and flows
- **[Workers](./meta-9_worker_groups-index.md)** - Monitor [worker status and configuration](./meta-9_worker_groups-index.md), including worker groups and resource allocation

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/De77j1T3gRs"
	title="Windmill MCP"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>
