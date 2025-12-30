---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-3
heading_path: ["arguments", "Boolean arguments"]
chunk_type: code
tokens: 126
summary: "Here is an example of a Dagger Function that accepts a Boolean argument:

**Go:**
```go
package m..."
---
Here is an example of a Dagger Function that accepts a Boolean argument:

**Go:**
```go
package main

import (
	"strings"
)

type MyModule struct{}

func (m *MyModule) Hello(shout bool) string {
	message := "Hello, world"
	if shout {
		return strings.ToUpper(message)
	}
	return message
}
```

Here is an example call for this Dagger Function:

```bash
dagger call hello --shout=true
```

The result will look like this:

```
HELLO, WORLD
```

> **Note:** When passing optional boolean flags:
> - To set the argument to true: `--foo=true` or `--foo`
> - To set the argument to false: `--foo=false`
