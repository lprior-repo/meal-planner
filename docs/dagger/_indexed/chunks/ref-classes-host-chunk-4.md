---
doc_id: ref/classes/host
chunk_id: ref/classes/host#chunk-4
heading_path: ["host", "Methods"]
chunk_type: prose
tokens: 380
summary: "> **containerImage**(`name`): [`Container`](/reference/typescript/api/client."
---
### containerImage()

> **containerImage**(`name`): [`Container`](/reference/typescript/api/client.gen/classes/Container)

Accesses a container image on the host.

#### Parameters

#### name

`string`

Name of the image to access.

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### directory()

> **directory**(`path`, `opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Accesses a directory on the host.

#### Parameters

#### path

`string`

Location of the directory to access (e.g., ".").

#### opts?

[`HostDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/HostDirectoryOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### file()

> **file**(`path`, `opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Accesses a file on the host.

#### Parameters

#### path

`string`

Location of the file to retrieve (e.g., "README.md").

#### opts?

[`HostFileOpts`](/reference/typescript/api/client.gen/type-aliases/HostFileOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### findUp()

> **findUp**(`name`, `opts?`): `Promise`<`string`\>

Search for a file or directory by walking up the tree from system workdir. Return its relative path. If no match, return null

#### Parameters

#### name

`string`

name of the file or directory to search for

#### opts?

[`HostFindUpOpts`](/reference/typescript/api/client.gen/type-aliases/HostFindUpOpts)

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`HostID`](/reference/typescript/api/client.gen/type-aliases/HostID)\>

A unique identifier for this Host.

#### Returns

`Promise`<[`HostID`](/reference/typescript/api/client.gen/type-aliases/HostID)\>

---

### service()

> **service**(`ports`, `opts?`): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Creates a service that forwards traffic to a specified address via the host.

#### Parameters

#### ports

[`PortForward`](/reference/typescript/api/client.gen/type-aliases/PortForward)\[\]

Ports to expose via the service, forwarding through the host network.

If a port's frontend is unspecified or 0, it defaults to the same as the backend port.

An empty set of ports is not valid; an error will be returned.

#### opts?

[`HostServiceOpts`](/reference/typescript/api/client.gen/type-aliases/HostServiceOpts)

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### tunnel()

> **tunnel**(`service`, `opts?`): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Creates a tunnel that forwards traffic from the host to a service.

#### Parameters

#### service

[`Service`](/reference/typescript/api/client.gen/classes/Service)

Service to send traffic from the tunnel.

#### opts?

[`HostTunnelOpts`](/reference/typescript/api/client.gen/type-aliases/HostTunnelOpts)

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### unixSocket()

> **unixSocket**(`path`): [`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Accesses a Unix socket on the host.

#### Parameters

#### path

`string`

Location of the Unix socket (e.g., "/var/run/docker.sock").

#### Returns

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)
