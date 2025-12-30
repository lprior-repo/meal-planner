---
id: ref/classes/engine
title: "Class: Engine"
category: ref
tags: ["ref", "api", "typescript", "cache", "cli"]
---

# Class: Engine

> **Context**: The Dagger engine configuration and state


The Dagger engine configuration and state

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Engine**(`ctx?`, `_id?`, `_name?`): `Engine`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)

#### \_name?

`string`

#### Returns

`Engine`

#### Overrides

`BaseClient.constructor`

## Methods

### clients()

> **clients**(): `Promise`<`string`\[\]>

The list of connected client IDs

#### Returns

`Promise`<`string`\[\]>

---

### id()

> **id**(): `Promise`<[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)\>

A unique identifier for this Engine.

#### Returns

`Promise`<[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)\>

---

### localCache()

> **localCache**(): [`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

The local (on-disk) cache for the Dagger engine

#### Returns

[`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

---

### name()

> **name**(): `Promise`<`string`\>

The name of the engine instance.

#### Returns

`Promise`<`string`\>

## See Also

- [Documentation Overview](./COMPASS.md)
