---
id: ref/classes/cloud
title: "Class: Cloud"
category: ref
tags: ["ref", "api", "trace", "cloud", "typescript"]
---

# Class: Cloud

> **Context**: Dagger Cloud configuration and state


Dagger Cloud configuration and state

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Cloud**(`ctx?`, `_id?`, `_traceURL?`): `Cloud`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`CloudID`](/reference/typescript/api/client.gen/type-aliases/CloudID)

#### \_traceURL?

`string`

#### Returns

`Cloud`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`CloudID`](/reference/typescript/api/client.gen/type-aliases/CloudID)\>

A unique identifier for this Cloud.

#### Returns

`Promise`<[`CloudID`](/reference/typescript/api/client.gen/type-aliases/CloudID)\>

---

### traceURL()

> **traceURL**(): `Promise`<`string`\>

The trace URL for the current session

#### Returns

`Promise`<`string`\>

## See Also

- [Documentation Overview](./COMPASS.md)
