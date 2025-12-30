# Class: Address

A standardized address to load containers, directories, secrets, and other object types. Address format depends on the type, and is validated at type selection.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Address**(`ctx?`, `_id?`, `_value?`): `Address`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`AddressID`](/reference/typescript/api/client.gen/type-aliases/AddressID)

##### \_value?

`string`

#### Returns

`Address`

#### Overrides

`BaseClient.constructor`

## Methods

### container()

> **container**(): [`Container`](/reference/typescript/api/client.gen/classes/Container)

Load a container from the address.

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### directory()

> **directory**(`opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Load a directory from the address.

#### Parameters

##### opts?

[`AddressDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/AddressDirectoryOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### file()

> **file**(`opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Load a file from the address.

#### Parameters

##### opts?

[`AddressFileOpts`](/reference/typescript/api/client.gen/type-aliases/AddressFileOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### gitRef()

> **gitRef**(): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Load a git ref (branch, tag or commit) from the address.

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### gitRepository()

> **gitRepository**(): [`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

Load a git repository from the address.

#### Returns

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

---

### id()

> **id**(): `Promise`<[`AddressID`](/reference/typescript/api/client.gen/type-aliases/AddressID)\>

A unique identifier for this Address.

#### Returns

`Promise`<[`AddressID`](/reference/typescript/api/client.gen/type-aliases/AddressID)\>

---

### secret()

> **secret**(): [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Load a secret from the address.

#### Returns

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

---

### service()

> **service**(): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Load a service from the address.

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### socket()

> **socket**(): [`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Load a local socket from the address.

#### Returns

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

---

### value()

> **value**(): `Promise`<`string`\>

The address value

#### Returns

`Promise`<`string`\>
