---
id: ref/classes/terminal
title: "Class: Terminal"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: Terminal

> **Context**: An interactive terminal that clients can connect to.


An interactive terminal that clients can connect to.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Terminal**(`ctx?`, `_id?`, `_sync?`): `Terminal`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)

#### \_sync?

[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)

#### Returns

`Terminal`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)\>

A unique identifier for this Terminal.

#### Returns

`Promise`<[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)\>

---

### sync()

> **sync**(): `Promise`<`Terminal`\>

Forces evaluation of the pipeline in the engine.

It doesn't run the default command if no exec has been set.

#### Returns

`Promise`<`Terminal`\>

## See Also

- [Documentation Overview](./COMPASS.md)
