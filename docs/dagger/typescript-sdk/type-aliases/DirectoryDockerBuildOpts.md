# Type Alias: DirectoryDockerBuildOpts

> **DirectoryDockerBuildOpts** = `object`

## Properties

### buildArgs?

> `optional` **buildArgs**: [`BuildArg`](/reference/typescript/api/client.gen/type-aliases/BuildArg)[]

Build arguments to use in the build.

---

### dockerfile?

> `optional` **dockerfile**: `string`

Path to the Dockerfile to use (e.g., "frontend.Dockerfile").

---

### noInit?

> `optional` **noInit**: `boolean`

If set, skip the automatic init process injected into containers created by RUN statements.

This should only be used if the user requires that their exec processes be the pid 1 process in the container. Otherwise it may result in unexpected behavior.

---

### platform?

> `optional` **platform**: [`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)

The platform to build.

---

### secrets?

> `optional` **secrets**: [`Secret`](/reference/typescript/api/client.gen/classes/Secret)[]

Secrets to pass to the build.

They will be mounted at /run/secrets/[secret-name].

---

### target?

> `optional` **target**: `string`

Target build stage to build.
