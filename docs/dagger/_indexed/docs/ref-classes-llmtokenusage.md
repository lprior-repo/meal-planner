---
id: ref/classes/llmtokenusage
title: "Class: LLMTokenUsage"
category: ref
tags: ["ref", "api", "typescript", "cache", "llm"]
---

# Class: LLMTokenUsage

> **Context**: > **new LLMTokenUsage**(`ctx?`, `_id?`, `_cachedTokenReads?`, `_cachedTokenWrites?`, `_inputTokens?`, `_outputTokens?`, `_totalTokens?`): `LLMTokenUsa...


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new LLMTokenUsage**(`ctx?`, `_id?`, `_cachedTokenReads?`, `_cachedTokenWrites?`, `_inputTokens?`, `_outputTokens?`, `_totalTokens?`): `LLMTokenUsage`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`LLMTokenUsageID`](/reference/typescript/api/client.gen/type-aliases/LLMTokenUsageID)

#### \_cachedTokenReads?

`number`

#### \_cachedTokenWrites?

`number`

#### \_inputTokens?

`number`

#### \_outputTokens?

`number`

#### \_totalTokens?

`number`

#### Returns

`LLMTokenUsage`

#### Overrides

`BaseClient.constructor`

## Methods

### cachedTokenReads()

> **cachedTokenReads**(): `Promise`<`number`\>

#### Returns

`Promise`<`number`\>

---

### cachedTokenWrites()

> **cachedTokenWrites**(): `Promise`<`number`\>

#### Returns

`Promise`<`number`\>

---

### id()

> **id**(): `Promise`<[`LLMTokenUsageID`](/reference/typescript/api/client.gen/type-aliases/LLMTokenUsageID)\>

A unique identifier for this LLMTokenUsage.

#### Returns

`Promise`<[`LLMTokenUsageID`](/reference/typescript/api/client.gen/type-aliases/LLMTokenUsageID)\>

---

### inputTokens()

> **inputTokens**(): `Promise`<`number`\>

#### Returns

`Promise`<`number`\>

---

### outputTokens()

> **outputTokens**(): `Promise`<`number`\>

#### Returns

`Promise`<`number`\>

---

### totalTokens()

> **totalTokens**(): `Promise`<`number`\>

#### Returns

`Promise`<`number`\>

## See Also

- [Documentation Overview](./COMPASS.md)
