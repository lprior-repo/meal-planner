---
doc_id: ops/moonrepo/pkl-config
chunk_id: ops/moonrepo/pkl-config#chunk-5
heading_path: ["Pkl configuration", "Example functionality"]
chunk_type: code
tokens: 107
summary: "Example functionality"
---

## Example functionality

### Loops and conditionals

```pkl
tasks {
  for (_os in List("linux", "macos", "windows")) {
    ["build-\(_os)"] {
      command = "cargo"
      args = List(
        "--target",
        if (_os == "linux") "x86_64-unknown-linux-gnu"
          else if (_os == "macos") "x86_64-apple-darwin"
          else "i686-pc-windows-msvc",
        "--verbose"
      )
      options {
        os = _os
      }
    }
  }
}
```

### Local variables

```pkl
local _sharedInputs = List("src/**/*")

tasks {
  ["test"] {
    // ...
    inputs = List("tests/**/*") + _sharedInputs
  }
  ["lint"] {
    // ...
    inputs = List("**/*.graphql") + _sharedInputs
  }
}
```
