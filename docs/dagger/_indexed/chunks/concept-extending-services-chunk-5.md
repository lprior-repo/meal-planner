---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-5
heading_path: ["services", "Expose host services to functions"]
chunk_type: mixed
tokens: 183
summary: "Dagger Functions can also receive host services as function arguments of type `Service`, in the f..."
---
Dagger Functions can also receive host services as function arguments of type `Service`, in the form `tcp://<host>:<port>`. This enables client containers in Dagger Functions to communicate with services running on the host.

> **Note:** This implies that a service is already listening on a port on the host, out-of-band of Dagger.

Here is an example of how a container running in a Dagger Function can access and query a MariaDB database service (bound using the alias `db`) running on the host.

Before calling this Dagger Function, use the following command to start a MariaDB database service on the host:

```bash
docker run --rm --detach -p 3306:3306 --name my-mariadb --env MARIADB_ROOT_PASSWORD=secret  mariadb:10.11.2
```

Here is an example call for this Dagger Function:

```bash
dagger call user-list --svc=tcp://localhost:3306
```

The result will be:

```
Host    User
%       root
localhost       mariadb.sys
localhost       root
```
