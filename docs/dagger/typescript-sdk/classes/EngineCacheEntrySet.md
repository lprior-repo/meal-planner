# Class: EngineCacheEntrySet

A set of cache entries returned by a query to a cache

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new EngineCacheEntrySet**(`ctx?`, `_id?`, `_diskSpaceBytes?`, `_entryCount?`): `EngineCacheEntrySet`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)

##### \_diskSpaceBytes?

`number`

##### \_entryCount?

`number`

#### Returns

`EngineCacheEntrySet`

#### Overrides

`BaseClient.constructor`

## Methods

### diskSpaceBytes()

> **diskSpaceBytes**(): `Promise`<`number`\>

The total disk space used by the cache entries in this set.

#### Returns

`Promise`<`number`\>

---

### entries()

> **entries**(): `Promise`<[`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)\[\]>

The list of individual cache entries in the set

#### Returns

`Promise`<[`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)\[\]>

---

### entryCount()

> **entryCount**(): `Promise`<`number`\>

The number of cache entries in this set.

#### Returns

`Promise`<`number`\>

---

### id()

> **id**(): `Promise`<[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)\>

A unique identifier for this EngineCacheEntrySet.

#### Returns

`Promise`<[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)\>
