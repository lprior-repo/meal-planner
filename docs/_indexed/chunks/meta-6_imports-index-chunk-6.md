---
doc_id: meta/6_imports/index
chunk_id: meta/6_imports/index#chunk-6
heading_path: ["Dependency management & imports", "Imports in Go"]
chunk_type: code
tokens: 87
summary: "Imports in Go"
---

## Imports in Go

For Go, the dependencies and their versions are contained in the
script and hence there is no need for any additional steps.

e.g:

```go
import (
	"rsc.io/quote"
    wmill "github.com/windmill-labs/windmill-go-client"
)
```

You can pin dependencies in Go using those annotations in the body of the script:

```go
// Pin dependencies partially in go.mod with a comment starting with "//require":
//require rsc.io/quote v1.5.1
```
