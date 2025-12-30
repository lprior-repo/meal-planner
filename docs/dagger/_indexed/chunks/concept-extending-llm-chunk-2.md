---
doc_id: concept/extending/llm
chunk_id: concept/extending/llm#chunk-2
heading_path: ["llm", "Prompts"]
chunk_type: code
tokens: 103
summary: "Use the `LLM."
---
Use the `LLM.withPrompt()` API method to append prompts to the LLM context:

**System shell:**
```bash
dagger <<EOF
llm |
  with-prompt "What tools do you have available?"
EOF
```

**Dagger Shell:**
```
llm |
  with-prompt "What tools do you have available?"
```

For longer or more complex prompts, use the `LLM.withPromptFile()` API method to read the prompt from a text file:

**System shell:**
```bash
dagger <<EOF
llm |
  with-prompt-file ./prompt.txt
EOF
```

**Dagger Shell:**
```
llm |
  with-prompt-file ./prompt.txt
```
