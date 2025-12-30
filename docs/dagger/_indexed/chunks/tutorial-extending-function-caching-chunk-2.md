---
doc_id: tutorial/extending/function-caching
chunk_id: tutorial/extending/function-caching#chunk-2
heading_path: ["function-caching", "Configure caching per function"]
chunk_type: code
tokens: 841
summary: "Functions without a `cache` attribute default to being cached with the maximum TTL, which is curr..."
---
### Default behavior

Functions without a `cache` attribute default to being cached with the maximum TTL, which is currently 7 days. This means that subsequent calls to the same function with the same inputs will return the same cached value, without executing, for up to 7 days.

**Go:**
```go
package main

import "crypto/rand"

type Tokens struct{}

func (Tokens) AlwaysCached() string {
    // No cache attribute -> defaults to the seven-day TTL.
    return rand.Text()
}
```

**Python:**
```python
import dagger
import secrets

@dagger.object_type
class Tokens:
    @dagger.function
    def always_cached(self) -> str:
        """No cache keyword -> defaults to the seven-day TTL."""
        return secrets.token_hex(8)
```

**TypeScript:**
```typescript
import crypto from "crypto";
import { object, func } from "@dagger.io/dagger";

@object()
export class Tokens {
  @func()
  async alwaysCached(): Promise<string> {
    // No cache option -> defaults to the seven-day TTL.
    return crypto.randomBytes(8).toString("hex");
  }
}
```

### TTL caching

Use a duration string to cache a function's result for a fixed window. Subsequent calls to the same function with the same inputs will return the same cached value, without executing, for up to the configured TTL. The TTL countdown starts when the function begins executing. When the TTL expires, the next call recomputes the function and refreshes the cached value.

Duration string are in the form of an integer plus a time unit of "s" (for seconds), "m" (for minutes) or "h" (for hours). For example, "10s" is 10 seconds and "42m" is 42 minutes.

Currently, the maximum value for a TTL is 7 days and the minimum value is 1s.

A common use case for TTL based caching is with data from external network sources. A function that retrieves data from the network can use the TTL to configure how often that data is refreshed, while still being able to save the work of the lookup for the duration of the TTL.

**Go:**
```go
package main

import "crypto/rand"

type Tokens struct{}

// +cache="10s"
func (Tokens) ShortLived() string {
    return rand.Text()
}
```

**Python:**
```python
import dagger
import secrets

@dagger.object_type
class Tokens:
    @dagger.function(cache="10s")
    def short_lived(self) -> str:
        return secrets.token_hex(8)
```

**TypeScript:**
```typescript
import crypto from "crypto";
import { object, func } from "@dagger.io/dagger";

@object()
export class Tokens {
  @func({ cache: "10s" })
  async shortLived(): Promise<string> {
    return crypto.randomBytes(8).toString("hex");
  }
}
```

### Session caching

`cache="session"` keeps results only for the lifetime of the current engine session. An engine session starts when a client connects to the engine and ends when that client disconnects. The client may be the CLI (e.g. `dagger call` or `dagger -c`) or any of the Dagger SDKs running as a custom application on your host.

Session caching is useful in situations where one function call may be repeated throughout the session (e.g. one function call repeatedly made by other functions). In those cases, if the result of the function call should be shared by all callers in the session, but not leak to other separate clients concurrently connected, session-based caching should be used.

**Go:**
```go
package main

import "crypto/rand"

type Tokens struct{}

// +cache="session"
func (Tokens) PerSession() string {
    return rand.Text()
}
```

**Python:**
```python
import dagger
import secrets

@dagger.object_type
class Tokens:
    @dagger.function(cache="session")
    def per_session(self) -> str:
        return secrets.token_hex(8)
```

**TypeScript:**
```typescript
import crypto from "crypto";
import { object, func } from "@dagger.io/dagger";

@object()
export class Tokens {
  @func({ cache: "session" })
  async perSession(): Promise<string> {
    return crypto.randomBytes(8).toString("hex");
  }
}
```

### Never cache

`cache="never"` opts the function out of both persistent and per-session caching, ensuring the function runs on every call.

**Go:**
```go
package main

import "crypto/rand"

type Tokens struct{}

// +cache="never"
func (Tokens) NoCache() string {
    return rand.Text()
}
```

**Python:**
```python
import dagger
import secrets

@dagger.object_type
class Tokens:
    @dagger.function(cache="never")
    def no_cache(self) -> str:
        return secrets.token_hex(8)
```

**TypeScript:**
```typescript
import crypto from "crypto";
import { object, func } from "@dagger.io/dagger";

@object()
export class Tokens {
  @func({ cache: "never" })
  async noCache(): Promise<string> {
    return crypto.randomBytes(8).toString("hex");
  }
}
```
