# Type Alias: ContainerExistsOpts

> **ContainerExistsOpts** = `object`

## Properties

### doNotFollowSymlinks?

> `optional` **doNotFollowSymlinks**: `boolean`

If specified, do not follow symlinks.

---

### expectedType?

> `optional` **expectedType**: [`ExistsType`](/reference/typescript/api/client.gen/enumerations/ExistsType)

If specified, also validate the type of file (e.g. "REGULAR_TYPE", "DIRECTORY_TYPE", or "SYMLINK_TYPE").
