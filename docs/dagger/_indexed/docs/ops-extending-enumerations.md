---
id: ops/extending/enumerations
title: "Enumerations"
category: ops
tags: ["ops", "cache", "module", "function", "container"]
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
```python
import enum

from dagger import dag, enum_type, function, object_type


@enum_type
class Severity(enum.Enum):
    """Vulnerability severity levels"""

    UNKNOWN = "UNKNOWN"
    """Undetermined risk; analyze further"""

    LOW = "LOW"
    """Minimal risk; routine fix"""

    MEDIUM = "MEDIUM"
    """Moderate risk; timely fix"""

    HIGH = "HIGH"
    """Serious risk; quick fix needed."""

    CRITICAL = "CRITICAL"
    """Severe risk; immediate action."""


@object_type
class MyModule:
    @function
    def scan(self, ref: str, severity: Severity) -> str:
        ctr = dag.container().from_(ref)
        return (
            dag.container()
            .from_("aquasec/trivy:0.50.4")
            .with_mounted_file("/mnt/ctr.tar", ctr.as_tarball())
            .with_mounted_cache("/root/.cache", dag.cache_volume("trivy-cache"))
            .with_exec(
                [
                    "trivy",
                    "image",
                    "--format=json",
                    "--no-progress",
                    "--exit-code=1",
                    "--vuln-type=os,library",
                    "--severity=" + severity.name,
                    "--show-suppressed",
                    "--input=/mnt/ctr.tar",
                ]
            )
            .stdout()
        )
```

**TypeScript:**
```typescript
import { dag, object, func } from "@dagger.io/dagger"

/**
 * Vulnerability severity levels
 */
export enum Severity {
  /**
   * Undetermined risk; analyze further.
   */
  Unknown = "UNKNOWN",
  /**
   * Minimal risk; routine fix.
   */
  Low = "LOW",
  /**
   * Moderate risk; timely fix.
   */
  Medium = "MEDIUM",
  /**
   * Serious risk; quick fix needed.
   */
  High = "HIGH",
  /**
   * Severe risk; immediate action.
   */
  Critical = "CRITICAL",
}

@object()
class MyModule {
  @func()
  async scan(ref: string, severity: Severity): Promise<string> {
    const ctr = dag.container().from(ref)
    return dag
      .container()
      .from("aquasec/trivy:0.50.4")
      .withMountedFile("/mnt/ctr.tar", ctr.asTarball())
      .withMountedCache("/root/.cache", dag.cacheVolume("trivy-cache"))
      .withExec([
        "trivy",
        "image",
        "--format=json",
        "--no-progress",
        "--exit-code=1",
        "--vuln-type=os,library",
        `severity=${severity}`,
        "--show-suppressed",
        "--input=/mnt/ctr.tar",
      ])
      .stdout()
  }
}
```

**Java:**
```java
package io.dagger.modules.mymodule;

import io.dagger.module.annotation.Enum;

@Enum
public enum Severity {
  UNKNOWN,
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL
}
```

Enumeration choices will be displayed when calling `--help` or `.help` on a Dagger Function:

```bash
dagger call scan --help
```

The result will be:

```
USAGE
  dagger call scan [arguments]

ARGUMENTS
      --ref string                                  [required]
      --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL   [required]
```

Here's an example of calling the Dagger Function with an invalid enum argument:

```bash
dagger call scan --ref=hello-world:latest --severity=FOO
```

This will result in an error that displays possible values:

```
Error: invalid argument "FOO" for "--severity" flag: value should be one of UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
Run 'dagger call scan --help' for usage.
```

## See Also

- [Documentation Overview](./COMPASS.md)
