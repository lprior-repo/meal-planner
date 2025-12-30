---
id: ref/type-aliases/clientgitopts
title: "Type Alias: ClientGitOpts"
category: ref
tags: ["secret", "ref", "git", "service", "typescript"]
---

# Type Alias: ClientGitOpts

> **Context**: > **ClientGitOpts** = `object`


> **ClientGitOpts** = `object`

## Properties

### experimentalServiceHost?

> `optional` **experimentalServiceHost**: [`Service`](/reference/typescript/api/client.gen/classes/Service)

A service which must be started before the repo is fetched.

---

### httpAuthHeader?

> `optional` **httpAuthHeader**: [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Secret used to populate the Authorization HTTP header

---

### httpAuthToken?

> `optional` **httpAuthToken**: [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Secret used to populate the password during basic HTTP Authorization

---

### httpAuthUsername?

> `optional` **httpAuthUsername**: `string`

Username used to populate the password during basic HTTP Authorization

---

### keepGitDir?

> `optional` **keepGitDir**: `boolean`

DEPRECATED: Set to true to keep .git directory.

#### Deprecated

Set to true to keep .git directory.

---

### sshAuthSocket?

> `optional` **sshAuthSocket**: [`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Set SSH auth socket

---

### sshKnownHosts?

> `optional` **sshKnownHosts**: `string`

Set SSH known hosts

## See Also

- [Documentation Overview](./COMPASS.md)
