---
doc_id: ops/cookbook/services
chunk_id: ops/cookbook/services#chunk-8
heading_path: ["services", "Start and stop services"]
chunk_type: code
tokens: 316
summary: "```python
import contextlib

import dagger
from dagger import dag, function, object_type

@contex..."
---
### Python

```python
import contextlib

import dagger
from dagger import dag, function, object_type

@contextlib.asynccontextmanager
async def managed_service(svc: dagger.Service):
    """Start and stop a service."""
    yield await svc.start()
    await svc.stop()

@object_type
class MyModule:
    @function
    async def redis_service(self) -> str:
        """Explicitly start and stop a Redis service."""
        redis_srv = dag.container().from_("redis").with_exposed_port(6379).as_service()

        # start Redis ahead of time so it stays up for the duration of the test
        # and stop when done
        async with managed_service(redis_srv) as redis_srv:
            # create Redis client container
            redis_cli = (
                dag.container()
                .from_("redis")
                .with_service_binding("redis-srv", redis_srv)
            )

            args = ["redis-cli", "-h", "redis-srv"]

            # set value
            setter = await redis_cli.with_exec([*args, "set", "foo", "abc"]).stdout()

            # get value
            getter = await redis_cli.with_exec([*args, "get", "foo"]).stdout()

            return setter + getter
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Explicitly start and stop a Redis service
   */
  @func()
  async redisService(): Promise<string> {
    let redisSrv = dag
      .container()
      .from("redis")
      .withExposedPort(6379)
      .asService()

    // start Redis ahead of time so it stays up for the duration of the test
    redisSrv = await redisSrv.start()

    // stop the service when done
    await redisSrv.stop()

    // create Redis client container
    const redisCLI = dag
      .container()
      .from("redis")
      .withServiceBinding("redis-srv", redisSrv)

    const args = ["redis-cli", "-h", "redis-srv"]

    // set value
    const setter = await redisCLI
      .withExec([...args, "set", "foo", "abc"])
      .stdout()

    // get value
    const getter = await redisCLI.withExec([...args, "get", "foo"]).stdout()

    return setter + getter
  }
}
```

### Example

Start and stop a Redis service:

```bash
dagger call redis-service
```
