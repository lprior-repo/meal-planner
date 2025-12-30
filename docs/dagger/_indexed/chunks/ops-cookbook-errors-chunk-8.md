---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-8
heading_path: ["errors", "Create custom spans"]
chunk_type: code
tokens: 567
summary: "Dagger represents operations performed by a Dagger Function as OpenTelemetry spans."
---
Dagger represents operations performed by a Dagger Function as OpenTelemetry spans. Spans are typically used to separate tasks that are running in parallel, with each branch waiting for completion.

It is possible to instrument custom OpenTelemetry spans inside any Dagger Function. This allows you to define logical boundaries within complex workflows, measure execution time, and track nested operations with greater granularity. These custom spans appear in the Dagger TUI and Traces.

> **Warning**: The approach described below is experimental and may be deprecated in favor of a new OpenTelemetry span API.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/telemetry"

	"golang.org/x/sync/errgroup"
)

type MyModule struct{}

func (m *MyModule) Foo(ctx context.Context) error {
	// clone the source code repository
	source := dag.
		Git("https://github.com/dagger/hello-dagger").
		Branch("main").Tree()

	// list versions to test against
	versions := []string{"20", "22", "23"}

	// define errorgroup
	eg := new(errgroup.Group)

	// run tests concurrently
	// emit a span for each
	for _, version := range versions {
		eg.Go(func() (rerr error) {
			ctx, span := Tracer().Start(ctx, "running unit tests with Node "+version)
			defer telemetry.End(span, func() error { return rerr })
			_, err := dag.Container().
				From("node:"+version).
				WithDirectory("/src", source).
				WithWorkdir("/src").
				WithExec([]string{"npm", "install"}).
				WithExec([]string{"npm", "run", "test:unit", "run"}).
				Sync(ctx)
			return err
		})
	}
	return eg.Wait()
}
```

### Python

```python
import anyio
from opentelemetry import trace

from dagger import dag, function, object_type

tracer = trace.get_tracer(__name__)

@object_type
class MyModule:
    @function
    async def foo(self):
        # clone the source code repository
        source = dag.git("https://github.com/dagger/hello-dagger").branch("main").tree()

        # list versions to test against
        versions = ["20", "22", "23"]

        async def _test(version: str):
            with tracer.start_as_current_span(
                f"running unit tests with Node {version}"
            ):
                await (
                    dag.container()
                    .from_(f"node:{version}")
                    .with_directory("/src", source)
                    .with_workdir("/src")
                    .with_exec(["npm", "install"])
                    .with_exec(["npm", "run", "test:unit", "run"])
                    .sync()
                )

        # run tests concurrently
        # emit a span for each
        async with anyio.create_task_group() as tg:
            for version in versions:
                tg.start_soon(_test, version)
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"
import * as trace from "@dagger.io/dagger/telemetry"

@object()
export class MyModule {
  @func()
  async foo(): Promise<void> {
    // clone the source code repository
    const source = dag
      .git("https://github.com/dagger/hello-dagger")
      .branch("main")
      .tree()

    // list versions to test against
    const versions = ["20", "22", "23"]

    const tracer = trace.getTracer(MyModule.name)

    // run tests concurrently
    // emit a span for each
    await Promise.all(
      versions.map(async (version) => {
        await tracer.startActiveSpan(
          `running unit tests with Node ${version}`,
          async () => {
            await dag
              .container()
              .from(`node:${version}`)
              .withDirectory("/src", source)
              .withWorkdir("/src")
              .withExec(["npm", "install"])
              .withExec(["npm", "run", "test:unit", "run"])
              .sync()
          },
        )
      }),
    )
  }
}
```

### Example

Execute a Dagger Function to run unit tests on the `dagger/hello-dagger` source code repository with different versions of Node.js, emitting a custom span for each version tested:

```bash
dagger call foo
```
