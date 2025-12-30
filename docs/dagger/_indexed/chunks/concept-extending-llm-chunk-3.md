---
doc_id: concept/extending/llm
chunk_id: concept/extending/llm#chunk-3
heading_path: ["llm", "Responses and Variables"]
chunk_type: code
tokens: 287
summary: "Use the `LLM."
---
Use the `LLM.lastReply()` API method to obtain the last reply from the LLM, or the `LLM.history()` API method to get the complete message history.

> **Important:** Most LLM services impose rate limits (restrictions on the number of requests they will accept within a given time period). Dagger handles this gracefully with built-in rate limit detection and automatic retry with exponential backoff.

Dagger supports the use of variables in prompts. This allows you to interpolate results of other operations into an LLM prompt:

**System shell:**
```bash
dagger <<EOF
source=\$(container |
  from alpine |
  with-directory /src https://github.com/dagger/dagger |
  directory /src)

environment=\$(env |
  with-directory-input 'source' \$source 'a directory with source code')

llm |
  with-env \$environment |
  with-prompt "The directory also has some tools available." |
  with-prompt "Use the tools in the directory to read the first paragraph of the README.md file in the directory." |
  with-prompt "Reply with only the selected text." |
  last-reply
EOF
```

**Dagger Shell:**
```
source=$(container |
  from alpine |
  with-directory /src https://github.com/dagger/dagger |
  directory /src)

environment=$(env |
  with-directory-input 'source' $source 'a directory with source code')

llm |
  with-env $environment |
  with-prompt "The directory also has some tools available." |
  with-prompt "Use the tools in the directory to read the first paragraph of the README.md file in the directory." |
  with-prompt "Reply with only the selected text." |
  last-reply
```
