---
doc_id: meta/54_ai_agents/index
chunk_id: meta/54_ai_agents/index#chunk-7
heading_path: ["AI agents", "Debugging"]
chunk_type: prose
tokens: 174
summary: "Debugging"
---

## Debugging

![AI Agent Debugging](./ai_agent_debugging.png 'AI Agent Debugging')

### Flow-level visualization
Tool calls are displayed directly on the flow graph as separate nodes connected to the AI Agent step. You can click on these tool call nodes to view detailed execution information, including inputs, outputs, and execution logs.

### Detailed logging
In the logging panel of the AI Agent step, you can see the comprehensive logging:
- All input parameters passed to the AI agent
- Tool calls made by the AI, including which tools were selected and their inputs
- Individual tool execution results with full job details
- The final AI response and complete message history

This detailed view allows you to trace through the AI's decision-making process and verify that tools are being called correctly with the expected inputs and outputs.
