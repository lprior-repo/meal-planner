---
doc_id: meta/22_ai_generation/index
chunk_id: meta/22_ai_generation/index#chunk-3
heading_path: ["Windmill AI", "Windmill AI for scripts"]
chunk_type: prose
tokens: 692
summary: "Windmill AI for scripts"
---

## Windmill AI for scripts

### AI Chat

The script editor includes an integrated AI chat panel designed to assist with coding tasks directly. 
The assistant can generate code, identify and fix issues, suggest improvements, add documentation, and more.

You can open the AI chat panel using **Cmd+L** (Mac) or **Ctrl+L** (Windows/Linux). When you have code selected, it will automatically include the selected code in your message to the AI.

Key features:
- When the AI suggests code changes, you can apply or discard specific parts of the suggestion, rather than having to accept or reject the entire block.
- You can provide additional context to guide the AI's suggestions, such as database schemas, deployed script diffs, and runtime errors. Access the context menu by clicking the context button or typing `@` directly in the chat input.
- The panel includes built-in shortcuts for common tasks like fixing bugs or optimizing code.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ai_chat.mp4"
/>

### Code completion

The script editor includes code autocomplete that provides real-time suggestions as you type. 
Currently, this feature requires [Mistral Codestral](https://mistral.ai/news/codestral), which excels at code completion thanks to their specialized [FIM (Fill-in-Middle)](https://docs.mistral.ai/capabilities/code_generation/#fill-in-the-middle-endpoint) endpoint.

The autocomplete feature can be enabled globally in the workspace settings. Individual users can then toggle it on or off in their personal script editor settings.

### Summary copilot

From your code, the AI assistant can generate a script summary.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/summary_compilot.mp4"
/>

### Legacy AI features

The following guides are still applicable for code editing of inline scripts inside flows and apps.

#### Code generation

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ai_generation.mp4"
/>

<br />

In a [code editor](../../code_editor/index.mdx) (Script, Flow, Apps), click on `AI` and write a prompt describing what the script should do. The script will follow Windmill's main requirements and features (exposing a main function, importing libraries, using resource types, declaring required parameters with types). Moreover, when creating an SQL or GraphQL script, the AI assistant will take into account the database/GraphQL API schema **when selected**.

![Prompt](../../assets/code_editor/ai_gen.png 'Prompt')

:::tip Pro tips
The AI assistant is particularly effective when generating Python and TypeScript (Bun runtime) scripts, so we recommend using these languages when possible.
Moreover, you will get better results if you specify in the prompt what the script should take as parameters, what it should return, the specific integration and libraries it should use if any.
For instance, in the demo video above we wanted to generate a script that fetches the commits of a GitHub repository passed as a parameter, so we wrote: `fetch and return the commits of a given repository on GitHub using octokit`.
:::

#### Code editing

Inside the `AI Gen` popup, you can choose to edit the existing code rather than generating a new one. The assistant will modify the code according to your prompt.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ai_edit.mp4"
/>

#### Code fixing

Upon error when executing code, you will be offered to "AI Fix" it. The assistant will automatically read the code, explain what went wrong, and suggest a way to fix it.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ai_fix.mp4"
/>
