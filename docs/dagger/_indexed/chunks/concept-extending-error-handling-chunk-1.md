---
doc_id: concept/extending/error-handling
chunk_id: concept/extending/error-handling#chunk-1
heading_path: ["error-handling"]
chunk_type: code
tokens: 434
summary: "> **Context**: Dagger modules handle errors in the same way as the language they are written in."
---
# Error Handling

> **Context**: Dagger modules handle errors in the same way as the language they are written in. This allows you to support any kind of error handling that your appl...


Dagger modules handle errors in the same way as the language they are written in. This allows you to support any kind of error handling that your application requires. You can also use error handling to verify user input.

Here is an example Dagger Function that performs division and throws an error if the denominator is zero:

**Go:**
```go
// A Dagger module for saying hello world!

package main

import (
	"fmt"
)

type MyModule struct {}

func (*MyModule) Divide(a, b int) (int, error) {
	if b == 0 {
		return 0, fmt.Errorf("cannot divide by zero")
	}
	return a / b, nil
}
```

Error handling in Go modules follows typical Go error patterns with explicit `error` return values and `if err != nil` checks. You can also use error handling to verify user input.

**Python:**
```python
from dagger import function, object_type


@object_type
class MyModule:
    @function
    def divide(self, a: int, b: int) -> float:
        if b == 0:
            msg = "cannot divide by zero"
            raise ValueError(msg)
        return a / b
```

**TypeScript:**
```typescript
import { object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  divide(a: number, b: number): number {
    if (b == 0) {
      throw new Error("cannot divide by zero")
    }
    return a / b
  }
}
```

**PHP:**
```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\{DaggerObject, DaggerFunction};

#[DaggerObject]
class MyModule
{
    #[DaggerFunction]
    public function divide(int $a, int $b): float
    {
        if ($b === 0) {
            throw new \RuntimeException('Cannot divide by zero');
        }
        return $a / $b;
    }
}
```

**Java:**
```java
package io.dagger.modules.mymodule;

import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;

@Object
public class MyModule {
  @Function
  public int divide(int a, int b) {
    if (b == 0) {
      throw new IllegalArgumentException("cannot divide by zero");
    }
    return a / b;
  }
}
```

Here is an example call for this Dagger Function:

```bash
