---
id: ref/classes/cachevolume
title: "Class: CacheVolume"
category: ref
tags: ["ref", "api", "typescript", "cache", "cli"]
---

# Class: CacheVolume

> **Context**: A directory whose contents persist across runs.


A directory whose contents persist across runs.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new CacheVolume**(`ctx?`, `_id?`): `CacheVolume`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`CacheVolumeID`](/reference/typescript/api/client.gen/type-aliases/CacheVolumeID)

#### Returns

`CacheVolume`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`CacheVolumeID`](/reference/typescript/api/client.gen/type-aliases/CacheVolumeID)\>

A unique identifier for this CacheVolume.

#### Returns

`Promise`<[`CacheVolumeID`](/reference/typescript/api/client.gen/type-aliases/CacheVolumeID)\>

## See Also

- [Documentation Overview](./COMPASS.md)
