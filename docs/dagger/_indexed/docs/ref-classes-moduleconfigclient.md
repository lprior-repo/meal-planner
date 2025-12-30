---
id: ref/classes/moduleconfigclient
title: "Class: ModuleConfigClient"
category: ref
tags: ["ref", "api", "directory", "typescript", "module"]
---

# Class: ModuleConfigClient

> **Context**: The client generated for the module.


The client generated for the module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new ModuleConfigClient**(`ctx?`, `_id?`, `_directory?`, `_generator?`): `ModuleConfigClient`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`ModuleConfigClientID`](/reference/typescript/api/client.gen/type-aliases/ModuleConfigClientID)

#### \_directory?

`string`

#### \_generator?

`string`

#### Returns

`ModuleConfigClient`

#### Overrides

`BaseClient.constructor`

## Methods

### directory()

> **directory**(): `Promise`<`string`\>

The directory the client is generated in.

#### Returns

`Promise`<`string`\>

---

### generator()

> **generator**(): `Promise`<`string`\>

The generator to use

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`ModuleConfigClientID`](/reference/typescript/api/client.gen/type-aliases/ModuleConfigClientID)\>

A unique identifier for this ModuleConfigClient.

#### Returns

`Promise`<[`ModuleConfigClientID`](/reference/typescript/api/client.gen/type-aliases/ModuleConfigClientID)\>

## See Also

- [Documentation Overview](./COMPASS.md)
