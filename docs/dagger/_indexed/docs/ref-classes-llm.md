---
id: ref/classes/llm
title: "Class: LLM"
category: ref
tags: ["ref", "file", "service", "typescript", "function"]
---

# Class: LLM

> **Context**: > **new LLM**(`ctx?`, `_id?`, `_hasPrompt?`, `_historyJSON?`, `_lastReply?`, `_model?`, `_provider?`, `_step?`, `_sync?`, `_tools?`): `LLM`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new LLM**(`ctx?`, `_id?`, `_hasPrompt?`, `_historyJSON?`, `_lastReply?`, `_model?`, `_provider?`, `_step?`, `_sync?`, `_tools?`): `LLM`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)

#### \_hasPrompt?

`boolean`

#### \_historyJSON?

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

#### \_lastReply?

`string`

#### \_model?

`string`

#### \_provider?

`string`

#### \_step?

[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)

#### \_sync?

[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)

#### \_tools?

`string`

#### Returns

`LLM`

#### Overrides

`BaseClient.constructor`

## Methods

### attempt()

> **attempt**(`number_`): `LLM`

create a branch in the LLM's history

#### Parameters

#### number\_

`number`

#### Returns

`LLM`

---

### bindResult()

> **bindResult**(`name`): [`Binding`](/reference/typescript/api/client.gen/classes/Binding)

returns the type of the current state

#### Parameters

#### name

`string`

#### Returns

[`Binding`](/reference/typescript/api/client.gen/classes/Binding)

---

### env()

> **env**(): [`Env`](/reference/typescript/api/client.gen/classes/Env)

return the LLM's current environment

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---

### hasPrompt()

> **hasPrompt**(): `Promise`<`boolean`\>

Indicates whether there are any queued prompts or tool results to send to the model

#### Returns

`Promise`<`boolean`\>

---

### history()

> **history**(): `Promise`<`string`\[\]>

return the llm message history

#### Returns

`Promise`<`string`\[\]>

---

### historyJSON()

> **historyJSON**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

return the raw llm message history as json

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

---

### id()

> **id**(): `Promise`<[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)\>

A unique identifier for this LLM.

#### Returns

`Promise`<[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)\>

---

### lastReply()

> **lastReply**(): `Promise`<`string`\>

return the last llm reply from the history

#### Returns

`Promise`<`string`\>

---

### loop()

> **loop**(): `LLM`

Submit the queued prompt, evaluate any tool calls, queue their results, and keep going until the model ends its turn

#### Returns

`LLM`

---

### model()

> **model**(): `Promise`<`string`\>

return the model used by the llm

#### Returns

`Promise`<`string`\>

---

### provider()

> **provider**(): `Promise`<`string`\>

return the provider used by the llm

#### Returns

`Promise`<`string`\>

---

### step()

> **step**(): `Promise`<`LLM`\>

Submit the queued prompt or tool call results, evaluate any tool calls, and queue their results

#### Returns

`Promise`<`LLM`\>

---

### sync()

> **sync**(): `Promise`<`LLM`\>

synchronize LLM state

#### Returns

`Promise`<`LLM`\>

---

### tokenUsage()

> **tokenUsage**(): [`LLMTokenUsage`](/reference/typescript/api/client.gen/classes/LLMTokenUsage)

returns the token usage of the current state

#### Returns

[`LLMTokenUsage`](/reference/typescript/api/client.gen/classes/LLMTokenUsage)

---

### tools()

> **tools**(): `Promise`<`string`\>

print documentation for available tools

#### Returns

`Promise`<`string`\>

---

### with()

> **with**(`arg`): `LLM`

Call the provided function with current LLM.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `LLM`

#### Returns

`LLM`

---

### withBlockedFunction()

> **withBlockedFunction**(`typeName`, `function_`): `LLM`

Return a new LLM with the specified function no longer exposed as a tool

#### Parameters

#### typeName

`string`

The type name whose function will be blocked

#### function\_

`string`

#### Returns

`LLM`

---

### withEnv()

> **withEnv**(`env`): `LLM`

allow the LLM to interact with an environment via MCP

#### Parameters

#### env

[`Env`](/reference/typescript/api/client.gen/classes/Env)

#### Returns

`LLM`

---

### withMCPServer()

> **withMCPServer**(`name`, `service`): `LLM`

Add an external MCP server to the LLM

#### Parameters

#### name

`string`

The name of the MCP server

#### service

[`Service`](/reference/typescript/api/client.gen/classes/Service)

The MCP service to run and communicate with over stdio

#### Returns

`LLM`

---

### withModel()

> **withModel**(`model`): `LLM`

swap out the llm model

#### Parameters

#### model

`string`

The model to use

#### Returns

`LLM`

---

### withoutDefaultSystemPrompt()

> **withoutDefaultSystemPrompt**(): `LLM`

Disable the default system prompt

#### Returns

`LLM`

---

### withoutMessageHistory()

> **withoutMessageHistory**(): `LLM`

Clear the message history, leaving only the system prompts

#### Returns

`LLM`

---

### withoutSystemPrompts()

> **withoutSystemPrompts**(): `LLM`

Clear the system prompts, leaving only the default system prompt

#### Returns

`LLM`

---

### withPrompt()

> **withPrompt**(`prompt`): `LLM`

append a prompt to the llm context

#### Parameters

#### prompt

`string`

The prompt to send

#### Returns

`LLM`

---

### withPromptFile()

> **withPromptFile**(`file`): `LLM`

append the contents of a file to the llm context

#### Parameters

#### file

[`File`](/reference/typescript/api/client.gen/classes/File)

The file to read the prompt from

#### Returns

`LLM`

---

### withStaticTools()

> **withStaticTools**(): `LLM`

Use a static set of tools for method calls, e.g. for MCP clients that do not support dynamic tool registration

#### Returns

`LLM`

---

### withSystemPrompt()

> **withSystemPrompt**(`prompt`): `LLM`

Add a system prompt to the LLM's environment

#### Parameters

#### prompt

`string`

The system prompt to send

#### Returns

`LLM`

## See Also

- [Documentation Overview](./COMPASS.md)
