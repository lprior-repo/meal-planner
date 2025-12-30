---
id: ref/classes/enginecache
title: "Class: EngineCache"
category: ref
tags: ["ref", "api", "typescript", "cache", "cli"]
---

# Class: EngineCache

> **Context**: A cache storage for the Dagger engine


A cache storage for the Dagger engine

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new EngineCache**(`ctx?`, `_id?`, `_maxUsedSpace?`, `_minFreeSpace?`, `_prune?`, `_reservedSpace?`, `_targetSpace?`): `EngineCache`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)

#### \_maxUsedSpace?

`number`

#### \_minFreeSpace?

`number`

#### \_prune?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

#### \_reservedSpace?

`number`

#### \_targetSpace?

`number`

#### Returns

`EngineCache`

#### Overrides

`BaseClient.constructor`

## Methods

### entrySet()

> **entrySet**(`opts?`): [`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

The current set of entries in the cache

#### Parameters

#### opts?

[`EngineCacheEntrySetOpts`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetOpts)

#### Returns

[`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

---

### id()

> **id**(): `Promise`<[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)\>

A unique identifier for this EngineCache.

#### Returns

`Promise`<[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)\>

---

### maxUsedSpace()

> **maxUsedSpace**(): `Promise`<`number`\>

The maximum bytes to keep in the cache without pruning.

#### Returns

`Promise`<`number`\>

---

### minFreeSpace()

> **minFreeSpace**(): `Promise`<`number`\>

The target amount of free disk space the garbage collector will attempt to leave.

#### Returns

`Promise`<`number`\>

---

### prune()

> **prune**(`opts?`): `Promise`<`void`\>

Prune the cache of releaseable entries

#### Parameters

#### opts?

[`EngineCachePruneOpts`](/reference/typescript/api/client.gen/type-aliases/EngineCachePruneOpts)

#### Returns

`Promise`<`void`\>

---

### reservedSpace()

> **reservedSpace**(): `Promise`<`number`\>

The minimum amount of disk space this policy is guaranteed to retain.

#### Returns

`Promise`<`number`\>

---

### targetSpace()

> **targetSpace**(): `Promise`<`number`\>

The target number of bytes to keep when pruning.

#### Returns

`Promise`<`number`\>

## See Also

- [Documentation Overview](./COMPASS.md)
