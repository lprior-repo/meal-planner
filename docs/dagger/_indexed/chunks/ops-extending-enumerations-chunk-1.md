---
doc_id: ops/extending/enumerations
chunk_id: ops/extending/enumerations#chunk-1
heading_path: ["enumerations"]
chunk_type: code
tokens: 351
summary: "> **Context**: > **Important:** The information on this page is only applicable to Go, Python and..."
---
# Enumerations

> **Context**: > **Important:** The information on this page is only applicable to Go, Python and TypeScript SDKs. Enumerations are not currently supported in the PH...


> **Important:** The information on this page is only applicable to Go, Python and TypeScript SDKs. Enumerations are not currently supported in the PHP SDK.

Dagger supports custom enumeration (enum) types, which can be used to restrict possible values for a string argument. Enum values are strictly validated, preventing common mistakes like accidentally passing null, true, or false.

> **Note:** Following the [GraphQL specification](https://spec.graphql.org/October2021/#Name), enums are represented as strings in the Dagger API GraphQL schema and follow these rules:
> - Enum names cannot start with digits, and can only be composed of alphabets, digits or `_`.
> - Enum values are case-sensitive, and by convention should be upper-cased.

Here is an example of a Dagger Function that takes two arguments: an image reference and a severity filter. The latter is defined as an enum named `Severity`:

**Go:**
```go
package main

import (
	"context"
)

type MyModule struct{}

// Vulnerability severity levels
type Severity string

const (
	// Undetermined risk; analyze further.
	Unknown Severity = "UNKNOWN"
	// Minimal risk; routine fix.
	Low Severity = "LOW"
	// Moderate risk; timely fix.
	Medium Severity = "MEDIUM"
	// Serious risk; quick fix needed.
	High Severity = "HIGH"
	// Severe risk; immediate action.
	Critical Severity = "CRITICAL"
)

func (m *MyModule) Scan(ctx context.Context, ref string, severity Severity) (string, error) {
	ctr := dag.Container().From(ref)
	return dag.Container().
		From("aquasec/trivy:0.50.4").
		WithMountedFile("/mnt/ctr.tar", ctr.AsTarball()).
		WithMountedCache("/root/.cache", dag.CacheVolume("trivy-cache")).
		WithExec([]string{
			"trivy",
			"image",
			"--format=json",
			"--no-progress",
			"--exit-code=1",
			"--vuln-type=os,library",
			"--severity=" + string(severity),
			"--show-suppressed",
			"--input=/mnt/ctr.tar",
		}).Stdout(ctx)
}
```

**Python:**
