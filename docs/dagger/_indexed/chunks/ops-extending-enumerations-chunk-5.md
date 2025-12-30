---
doc_id: ops/extending/enumerations
chunk_id: ops/extending/enumerations#chunk-5
heading_path: ["enumerations"]
chunk_type: code
tokens: 140
summary: "**Java:**
```java
package io."
---
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
