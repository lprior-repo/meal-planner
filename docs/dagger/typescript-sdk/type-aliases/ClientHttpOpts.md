# Type Alias: ClientHttpOpts

> **ClientHttpOpts** = `object`

## Properties

### authHeader?

> `optional` **authHeader**: [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Secret used to populate the Authorization HTTP header

---

### experimentalServiceHost?

> `optional` **experimentalServiceHost**: [`Service`](/reference/typescript/api/client.gen/classes/Service)

A service which must be started before the URL is fetched.

---

### name?

> `optional` **name**: `string`

File name to use for the file. Defaults to the last part of the URL.

---

### permissions?

> `optional` **permissions**: `number`

Permissions to set on the file.
