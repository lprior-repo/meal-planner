---
doc_id: ops/extending/cache-volumes
chunk_id: ops/extending/cache-volumes#chunk-1
heading_path: ["cache-volumes"]
chunk_type: code
tokens: 604
summary: "> **Context**: Volume caching involves caching specific parts of the filesystem and reusing them ..."
---
# Cache Volumes

> **Context**: Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especial...


Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especially useful when dealing with package managers such as `npm`, `maven`, `pip` and similar. Since these dependencies are usually locked to specific versions in the application's manifest, re-downloading them on every session is inefficient and time-consuming. By using a cache volume for these dependencies, Dagger can reuse the cached contents across Dagger Function runs and reduce execution time.

Here's an example:

**System shell:**
```bash
dagger <<EOF
container |
  from node:21 |
  with-directory /src https://github.com/dagger/hello-dagger |
  with-workdir /src |
  with-mounted-cache /root/.npm node-21 |
  with-exec npm install
EOF
```

**Dagger Shell:**
```
container |
  from node:21 |
  with-directory /src https://github.com/dagger/hello-dagger |
  with-workdir /src |
  with-mounted-cache /root/.npm node-21 |
  with-exec npm install
```

**Dagger CLI:**
```bash
dagger core container \
  from --address=node:21 \
  with-directory --path=/src --directory=https://github.com/dagger/hello-dagger \
  with-workdir --path=/src \
  with-mounted-cache --path=/root/.npm --cache=node-21 \
  with-exec --args="npm","install"
```

**Go:**
```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Build an application using cached dependencies
func (m *MyModule) Build(
	// Source code location
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("node:21").
		WithDirectory("/src", source).
		WithWorkdir("/src").
		WithMountedCache("/root/.npm", dag.CacheVolume("node-21")).
		WithExec([]string{"npm", "install"})
}
```

**Python:**
```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type


@object_type
class MyModule:
    @function
    def build(
        self, source: Annotated[dagger.Directory, Doc("Source code location")]
    ) -> dagger.Container:
        """Build an application using cached dependencies"""
        return (
            dag.container()
            .from_("node:21")
            .with_directory("/src", source)
            .with_workdir("/src")
            .with_mounted_cache("/root/.npm", dag.cache_volume("node-21"))
            .with_exec(["npm", "install"])
        )
```

**TypeScript:**
```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build an application using cached dependencies
   */
  @func()
  build(
    /**
     * Source code location
     */
    source: Directory,
  ): Container {
    return dag
      .container()
      .from("node:21")
      .withDirectory("/src", source)
      .withWorkdir("/src")
      .withMountedCache("/root/.npm", dag.cacheVolume("node-21"))
      .withExec(["npm", "install"])
  }
}
```

**PHP:**
```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\DaggerFunction;
use Dagger\Attribute\DaggerObject;
use Dagger\Attribute\Doc;
use Dagger\Container;
use Dagger\Directory;

use function Dagger\dag;

#[DaggerObject]
class MyModule
{
    #[DaggerFunction]
    #[Doc('Build an application using cached dependencies')]
    public function build(
      #[Doc('Source code location')]
      Directory $source,
    ): Container {
        return dag()
            ->container()
            ->from('node:21')
            ->withDirectory('/src', $source)
            ->withWorkdir('/src')
            ->withMountedCache('/root/.npm', dag()->cacheVolume('node-21'))
            ->withExec(['npm', 'install']);
    }
}
```

This example will take some time to complete on the first run, as the cache volumes will not exist at that point. Subsequent runs will be significantly faster (assuming there is no other change), since Dagger will simply use the dependencies from the cache volumes instead of downloading them again.

> **Note:** Cache volumes are scoped by default to the modules they're defined in. To share a cache volume across modules, you must intentionally pass a reference to it via constructor or function arguments.
