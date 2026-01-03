---
doc_id: concept/tandoor/templating
chunk_id: concept/tandoor/templating#chunk-3
heading_path: ["Templating", "Technical Reasoning"]
chunk_type: prose
tokens: 182
summary: "Technical Reasoning"
---

## Technical Reasoning
There are several options how the ingredients in the list can be related to the Template Context in the Text.

The template could access them by ID, the food name or the position in the list. All options have their benefits and disadvantages.

1. **ID**: ugly to write and read when not rendered and also more complex from a technical standpoint
2. **Name**: very nice to read and easy but does not work when a food occurs twice in a step. Could have workaround but would then be inconsistent.
3. **Position**: easy to write and understand but breaks when ordering is changed and not really nice to read when instructions are not rendered.

I decided to go for the position based system. If you know of any better way feel free to open an issue or PR.
