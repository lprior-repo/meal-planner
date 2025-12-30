---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-7
heading_path: ["Faq", "Why does the Text/Markdown preview look different than the final recipe?"]
chunk_type: prose
tokens: 119
summary: "Why does the Text/Markdown preview look different than the final recipe?"
---

## Why does the Text/Markdown preview look different than the final recipe?

Tandoor has always rendered the recipe instructions markdown on the server. This also allows tandoor to implement things like ingredient templating and scaling in text.
To make editing easier a markdown editor was added to the frontend with integrated preview as a temporary solution. Since the markdown editor uses a different
specification than the server the preview is different to the final result. It is planned to improve this in the future.

The markdown renderer follows this markdown specification https://daringfireball.net/projects/markdown/
