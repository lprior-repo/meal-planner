---
doc_id: ops/how-it-works/languages
chunk_id: ops/how-it-works/languages#chunk-2
heading_path: ["Languages", "Enabling a language"]
chunk_type: prose
tokens: 79
summary: "Enabling a language"
---

## Enabling a language

moon supported languages are opt-in, and *are not* enabled by default. We chose this pattern to avoid unnecessary overhead, especially for the future when we have 10 or more built-in languages.

To enable a supported language, simply define a configuration block with the language's name in `.moon/toolchain.yml`. Even an empty block will enable the language.

.moon/toolchain.yml

```yaml
