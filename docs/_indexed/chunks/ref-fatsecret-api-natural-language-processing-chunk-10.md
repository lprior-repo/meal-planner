---
doc_id: ref/fatsecret/api-natural-language-processing
chunk_id: ref/fatsecret/api-natural-language-processing#chunk-10
heading_path: ["Natural Language Processing API v1", "Best Practices"]
chunk_type: prose
tokens: 128
summary: "Best Practices"
---

## Best Practices

1. **Intermediate Screen**: After receiving results, show an intermediate screen allowing users to adjust servings before logging. This improves accuracy and user experience.

2. **Clear Input**: Encourage users to be specific about quantities (e.g., "two eggs" instead of "some eggs") for better matching.

3. **Eaten Foods Context**: Provide `eaten_foods` array when available to improve matching based on user's eating patterns and preferred brands.

4. **Error Handling**: Always handle error 211 gracefully - prompt users to rephrase or use manual food search.

5. **Input Validation**: Validate input length client-side before making API calls to avoid unnecessary requests.
