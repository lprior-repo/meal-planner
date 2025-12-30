---
doc_id: ops/guides/pkl-config
chunk_id: ops/guides/pkl-config#chunk-3
heading_path: ["Pkl configuration", "Using Pkl"]
chunk_type: code
tokens: 271
summary: "Using Pkl"
---

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
