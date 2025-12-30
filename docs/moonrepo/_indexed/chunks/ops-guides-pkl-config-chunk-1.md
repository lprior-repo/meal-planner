---
doc_id: ops/guides/pkl-config
chunk_id: ops/guides/pkl-config#chunk-1
heading_path: ["Pkl configuration"]
chunk_type: prose
tokens: 210
summary: "Pkl configuration"
---

# Pkl configuration

> **Context**: While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you have

v1.32.0

While YAML is our official configuration format, we want to support dynamic formats, and as such, have added support for Pkl. What is Pkl? If you haven't heard of Pkl yet, [Pkl is a programmable configuration format by Apple](https://pkl-lang.org/). We like Pkl, as it meets the following requirements:

- Is easy to read and write.
- Is dynamic and programmable (loops, variables, etc).
- Has type-safety / built-in schema support.
- Has Rust serde integration.

The primary requirement that we are hoping to achieve is supporting a configuration format that is *programmable*. We want something that has native support for variables, loops, conditions, and more, so that you could curate and compose your configuration very easily. Hacking this functionality into YAML is a terrible user experience in our opinion!
