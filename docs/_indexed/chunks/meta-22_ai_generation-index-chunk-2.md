---
doc_id: meta/22_ai_generation/index
chunk_id: meta/22_ai_generation/index#chunk-2
heading_path: ["Windmill AI", "Windmill AI Chat"]
chunk_type: prose
tokens: 481
summary: "Windmill AI Chat"
---

## Windmill AI Chat

The AI Chat in Windmill also includes a powerful navigation mode that serves as your personal assistant for understanding and using the platform. This mode goes beyond code generation to provide comprehensive help with Windmill itself.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/ZAlotkJlQ2c"
	title="Windmill AI Chat"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

The navigation mode can assist you with:

- **Answer questions about Windmill**: Get explanations about features, concepts, and best practices for using the platform effectively.
- **Navigate the app**: The AI can guide you through the Windmill interface, helping you locate specific features, settings, and tools you need.
- **Provide documentation links**: When you need more detailed information, the AI will direct you to relevant sections of this documentation for deeper learning.
- **Fetch API information**: The AI can retrieve and explain relevant API details to help you understand what data and options are available for your use case. 
- **Fill script and flow inputs**: Speed up your workflow by letting the AI automatically populate form fields for scripts and flows based on context and your requirements.
- **Custom form filling instructions**: You can provide specific instructions to the AI on how to fill out forms in script and flow settings, making it adapt to your particular workflow needs.

This navigation mode makes Windmill more accessible by providing contextual help exactly when and where you need it, whether you're learning the platform or looking for quick assistance during development.

### API mode

The AI chat also includes an API mode that allows you to perform basic operations on your Windmill workspace directly through conversation. You can interact with the following endpoints:

- **jobs**: Monitor, cancel, and retrieve information about running and completed jobs
- **scripts**: List, create, edit, and manage your scripts
- **flows**: Work with your flows and their configurations
- **resources**: Manage workspace resources and connections
- **variables**: Handle workspace and user variables
- **schedules**: Create and modify scheduled jobs
- **workers**: Check worker status and manage worker groups

These API endpoints are also available through the [Model Context Protocol (MCP)](./meta-51_mcp-index.md), enabling seamless integration with MCP-compatible tools and clients for automated workflow management.
