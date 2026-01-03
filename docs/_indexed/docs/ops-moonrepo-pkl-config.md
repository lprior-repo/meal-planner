---
id: ops/moonrepo/pkl-config
title: "Pkl configuration"
category: ops
tags: ["pkl", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Pkl configuration</title>
  <description>While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you haven&apos;t heard of Pkl yet, [Pkl is a programmable confi</description>
  <created_at>2026-01-02T19:55:27.183571</created_at>
  <updated_at>2026-01-02T19:55:27.183571</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Installing Pkl" level="2"/>
    <section name="Using Pkl" level="2"/>
    <section name="Caveats and restrictions" level="3"/>
    <section name="Example configs" level="2"/>
    <section name="`.moon/workspace.pkl`" level="3"/>
    <section name="`.moon/toolchain.pkl`" level="3"/>
    <section name="`moon.pkl`" level="3"/>
    <section name="Example functionality" level="2"/>
    <section name="Loops and conditionals" level="3"/>
    <section name="Local variables" level="3"/>
  </sections>
  <features>
    <feature>caveats_and_restrictions</feature>
    <feature>example_configs</feature>
    <feature>example_functionality</feature>
    <feature>installing_pkl</feature>
    <feature>local_variables</feature>
    <feature>loops_and_conditionals</feature>
    <feature>moonpkl</feature>
    <feature>moontoolchainpkl</feature>
    <feature>moonworkspacepkl</feature>
    <feature>using_pkl</feature>
  </features>
  <dependencies>
    <dependency type="crate">serde</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/template</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>pkl,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Pkl configuration

> **Context**: While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you have

v1.32.0

While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you haven't heard of Pkl yet, [Pkl is a programmable configuration format by Apple](https://pkl-lang.org/). We like Pkl, as it meets the following requirements:

- Is easy to read and write.
- Is dynamic and programmable (loops, variables, etc).
- Has type-safety / built-in schema support.
- Has Rust serde integration.

The primary requirement that we are hoping to achieve is supporting a configuration format that is *programmable*. We want something that has native support for variables, loops, conditions, and more, so that you could curate and compose your configuration very easily. Hacking this functionality into YAML is a terrible user experience in our opinion!

## Installing Pkl

Pkl utilizes a client-server architecture, which means that the `pkl` binary must exist in the environment for parsing and evaluating `.pkl` files. Jump over to the [official documentation for instructions on how to install Pkl](https://pkl-lang.org/main/current/pkl-cli/index.html#installation).

If you are using [proto](/proto), you can install Pkl with the following commands.

```shell
proto plugin add pkl https://raw.githubusercontent.com/milesj/proto-plugins/refs/heads/master/pkl.toml
proto install pkl --pin
```

## Using Pkl

To start using Pkl in moon, simply:

- Install [Pkl](#installing-pkl) and the [VS Code extension](https://pkl-lang.org/vscode/current/index.html)
- Create configs with the `.pkl` extension instead of `.yml`

> **Info:** We highly suggest reading the Pkl [language reference](https://pkl-lang.org/main/current/language-reference/index.html), the [standard library](https://pkl-lang.org/main/current/standard-library.html), or looking at our [example configurations](#example-configs) when using Pkl.

### Caveats and restrictions

Since this is an entirely new configuration format that is quite dynamic compared to YAML, there are some key differences to be aware of!

- Only files are supported. Cannot use or extend from URLs.

- Each `.pkl` file is evaluated in isolation (loops are processed, variables assigned, etc). This means that task inheritance and file merging cannot extend or infer this native functionality.

- `default` is a [special feature](https://pkl-lang.org/main/current/language-reference/index.html#default-element) in Pkl and cannot be used as a setting name. This only applies to [`template.pkl`](/docs/config/template#default), but can be worked around by using `defaultValue` instead.

template.pkl

```pkl
variables {
  ["age"] {
    type = "number"
    prompt = "Age?"
    defaultValue = 0
}
```

- `local` is also a reserved word in Pkl. It can be worked around by escaping it with backticks, or you can simply use the [`preset` setting](/docs/config/project#preset) instead.

```pkl
tasks {
  ["example"] {
    `local` = true
    # Or
    preset = "server"
  }
}
```

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


## See Also

- [proto](/proto)
- [Pkl](#installing-pkl)
- [example configurations](#example-configs)
- [`template.pkl`](/docs/config/template#default)
- [`preset` setting](/docs/config/project#preset)
