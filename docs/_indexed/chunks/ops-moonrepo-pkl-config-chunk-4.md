---
doc_id: ops/moonrepo/pkl-config
chunk_id: ops/moonrepo/pkl-config#chunk-4
heading_path: ["Pkl configuration", "Example configs"]
chunk_type: code
tokens: 139
summary: "Example configs"
---

## Example configs

### `.moon/workspace.pkl`

```pkl
projects {
  globs = List("apps/*", "packages/*")
  sources {
    ["root"] = "."
  }
}

vcs {
  defaultBranch = "master"
}
```

### `.moon/toolchain.pkl`

```pkl
node {
  version = "20.15.0"
  packageManager = "yarn"
  yarn {
    version = "4.3.1"
  }
  addEnginesConstraint = false
  inferTasksFromScripts = false
}
```

### `moon.pkl`

```pkl
type = "application"
language = "typescript"
dependsOn = List("client", "ui")

tasks {
  ["build"] {
    command = "docusaurus build"
    deps = List("^:build")
    outputs = List("build")
    options {
      interactive = true
      retryCount = 3
    }
  }
  ["typecheck"] {
    command = "tsc --build"
    inputs = new Listing {
      "@globs(sources)"
      "@globs(tests)"
      "tsconfig.json"
      "/tsconfig.options.json"
    }
  }
}
```
